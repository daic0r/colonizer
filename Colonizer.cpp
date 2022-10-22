#include "Colonizer.h"
#include <Components/TerrainComponent.h>
#include <Components/TextureComponent.h>
#include <Components/MeshComponent.h>
#include <Entities/EntityManager.h>
#include <System/SystemServices.h>
#include <glm/gtx/normal.hpp>
#include <Components/CameraComponent.h>
#include <Components/InputReceiverComponent.h>
#include <Events/EventQueue.h>
#include <Importers/ModelImporterOBJ.h>
#include <Components/TransformComponent.h>
#include <glm/mat4x4.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <Components/ModelReferenceComponent.h>
#include <Components/ModelInstanceTagComponent.h>
#include <Components/RenderMaterialsComponent.h>
#include <Components/SunComponent.h>
#include <Components/SkyboxComponent.h>
#include <Components/TagComponent.h>
#include <Components/SharedComponent.h>
#include <Interfaces/IGraphicsSystem.h>
#include <Components/InputReceiverComponent.h>
#include <System/AABB.h>
#include <GUI/MousePicker.h>
#include <System/Ray.h>
#include <iostream>
#include <Components/Systems/EventHandlingSystem.h>
#include <Events/TerrainTileSelectedEventArgs.h>
#include <Interfaces/ITextManager.h>
#include <GUI/Theme.h>
#include <GUI/WidgetManager.h>
#include <nlohmann/json.hpp>
#include <fstream>
#include <Components/Systems/SaveSystem.h>
#include <crossguid/guid.hpp>
#include <System/File.h>
#include <GUI/ListBox.h>
#include <GUI/ImageView.h>
#include <GUI/Constraints/MarginConstraint.h>
#include <System/RGBA.h>
#include <GUI/TextEdit.h>
#include <GUI/Button.h>
#include <World/LowPolyTerrain.h>
#include <Utils/MeshGeneration/LowPolyTerrainIndexGenerator.h>
#include <Utils/MeshGeneration/LowPolyTerrainMeshGenerator.h>
#include <Components/Systems/MasterRenderingSystem.h>
#include <Interfaces/PostProcessing/IContrastChanger.h>
#include <Interfaces/PostProcessing/IGaussianBlur.h>
#include <glm/gtx/string_cast.hpp>
#include <Components/WaterTileComponent.h>
#include <random>
#include <Components/BiomeNodeComponent.h>
#include <Components/Systems/BiomeSystem.h>
#include <Components/Systems/TerrainSystem.h>
#include <Components/Systems/BeeSystem.h>
#include <Components/AnimatedMeshComponent.h>
#include <Components/AnimatedModelInstanceTagComponent.h>
#include <Components/ModelAnimationComponent.h>
#include <Components/SkeletonComponent.h>
#include <Importers/ModelImporterCollada.h>
#include <Importers/ModelImporterGlTF.h>
#include <Components/Systems/AnimatedModelRenderingSystem.h>
#include <Interfaces/IComponentManager.h>
#include <Components/CharacterComponent.h>
#include <Components/ActionComponents/WalkActionComponent.h>
#include <Components/ActionComponents/PlaceBiomeNodeActionComponent.h>

namespace Colonizer
{
    template<typename Component>
	static void serializeComponent(nlohmann::json& j, Component& comp) {
		auto ser = comp.getSerializables();
        nlohmann::json jComp;
		jComp.emplace("componentId", Component::id());
		auto& attribs = jComp["data"];
		ser.serialize(attribs);
        j.push_back(jComp);
	}
    
    bool Colonizer::loadData() {
        try {
            systemServices.getTextManager()->registerFont("Purisa");
            systemServices.getTextManager()->registerFont("Segoe UI");
        }
        catch (...) {
            return false;
        }
        return true;
    }

    void Colonizer::update(float fDeltaTime, Ice::IEventQueue* pEventQueue) noexcept 
    {
        using namespace Ice;
        Event event{};
        bool bRet{};
        while ((bRet = pEventQueue->popEvent(event))) {
            switch (event.id()) {
                default:
                break;
            }
        }

        /*
        static float fContrast = 0.0f;
        static bool bPositive = true;
        if (fContrast > 0.5f) {
            bPositive = !bPositive;
            fContrast = 0.5f;
        }
        if (fContrast < 0.0f) {
            bPositive = !bPositive;
            fContrast = 0.0f;
        }
        fContrast += fDeltaTime * (bPositive ? 1.0f : -1.0f);
        m_pChanger->setContrast(fContrast);
        */
        //m_inventoryWidget->update();
    }

    template<std::size_t Size>
    auto makeHeightMap(float& minHeight, float& maxHeight) {
        std::vector<float> ret;
        ret.resize(Size*Size);

        Ice::PerlinNoise p{};
        
        constexpr float fstartx = 10.501f;
        float fx{ fstartx }, fy{ 20.2f };
        float daMax{ -1000 }, daMin{ 1000 };
        float localMin = std::numeric_limits<float>::max();
        float localMax = -std::numeric_limits<float>::max();
        for (int y = 0; y < Size; y += 1) {
            for (int x = 0; x < Size; x += 1 ) {
                float val{};
                float div{};
                for (int o = 1; o < 4; ++o) {
                    val += p.octave(o, fx, fy, .0f);
                    div += 1.0f / (o);
                }
                //val /= div;
                localMin = std::min(localMin, val);
                localMax = std::max(localMax, val);
                //daMax = std::max(val, daMax);
                //daMin = std::min(val, daMin);
                //std::cout << val << " ";
                ret[Size*y + x] = val;
                fx += .09f;
            }
            fx = fstartx;
            fy += .09f;
        }	

        //std::cout << "\n\nMax = " << daMax << ", Min = " << daMin << "\n";
        for (auto& fx : ret) {
                fx *= 8.0f; 
                fx *= fx;
                daMax = std::max(fx, daMax);
                daMin = std::min(fx, daMin);
        }

        minHeight = daMin;
        maxHeight = daMax;

        for (auto& fx : ret) {
            fx -= minHeight;
        }
        maxHeight -= minHeight;
        minHeight = 0.0f;
    /*
        for (auto& fx : ret) {
                if (fx < daMin+.05f)
                    fx -= (fx-daMin+.05f);
        }
    */
        return ret;
    }

    void Colonizer::generateTerrain() {
        using MeshGen = Ice::MeshGeneration::LowPolyTerrainMeshGenerator<>;
        using namespace Ice;

        MeshGen g{ TERRAIN_SIZE, TERRAIN_SIZE };
        float fMinHeight,fMaxHeight;
        const auto vHeightMap = makeHeightMap<TERRAIN_SIZE>(fMinHeight, fMaxHeight);
        const auto tr = Ice::LowPolyTerrain{ 0, 0, 
                TERRAIN_TILE_SIZE, TERRAIN_TILE_SIZE,
                TERRAIN_SIZE, TERRAIN_SIZE,
                vHeightMap,
                g.indexGenerator()
            };

        constexpr std::array<Ice::RGBA, 2> arColors {
            Ice::RGBA( 71, 19, 15 ),
            //Ice::RGBA( 36, 201, 130 )
           // Ice::RGBA( 255, 255, 255 )
        };
        const auto retIndices = g.generateIndices();
        const auto [retVerts,retColors] = g.generateVerticesAndColors(TERRAIN_TILE_SIZE, TERRAIN_TILE_SIZE, fMinHeight, fMaxHeight, vHeightMap, arColors );
        for (int i = 0; i < 36; i+=3)
            std::cout << retVerts[i] << " " << retVerts[i+1] << " " << retVerts[i+2] << "\n";
        std::cout << "Terrain has " << retVerts.size() << " vertices\n";
        std::cout << "Terrain has " << retIndices.size() << " indices\n";
        const auto retNormals = g.generateNormals(retVerts, retIndices);
        m_terrainEnt = entityManager.createEntity();
        MeshComponent terrainMesh{};
        terrainMesh.indices() = retIndices;
        terrainMesh.vertices() = retVerts;
        terrainMesh.colors() = retColors;
        terrainMesh.normals() = retNormals;
        entityManager.addComponent(m_terrainEnt, terrainMesh);
        TerrainComponent terr{ tr, retColors };
        entityManager.addComponent(m_terrainEnt, terr);

        m_pTerrainSys = entityManager.getSystem<TerrainSystem, false>();
        m_fTerrainMinHeight = fMinHeight;
    }

    void Colonizer::initGUI() {
        Ice::GUI::Theme t;

        t.textStyle().fontName() = "Segoe UI";
        t.textStyle().size() = 22.0f;
        t.textStyle().thickness() = .55f;
        t.color() = glm::vec4{ 11 * 1.0f/255.0f, 32 * 1.0f/255.0f, 39 * 1.0f/255.0f, 1.0f };
        t.foregroundColor() = glm::vec4{ 1.0f, 1.0f, 1.0f, 1.0f };
        systemServices.getWidgetManager().setTheme(t);
    }

    void Colonizer::init() 
    {
        using namespace Ice;

        generateTerrain();
        initGUI();
        
        //m_terrainEnt = generateTerrain(); 
        CameraComponent cam;
        cam.m_bPrimary = true;
        cam.m_camera.config().m_fDistance = 100.0f;
        cam.m_camera.config().m_fYawAgility = 5.0f;
        cam.m_camera.config().m_fMaxPitch = 89.0f;
        //cam.m_camera.config().m_fMaxDistance = 100.0f;
        cam.m_camera.initialize();        //cam.m_camera.setPitch(-20.0f);
        //cam.m_camera.updateViewLookAtVector();
        //cam.m_camera.setPosition(glm::vec3{ 30.0f, 20.0f, 50.0f });
        entityManager.addComponent(m_terrainEnt, cam);
        auto& camComp = entityManager.getComponent<CameraComponent>(m_terrainEnt).m_camera;

        entityManager.addComponent(m_terrainEnt, SkyboxComponent{});


        const auto& mainCamera = entityManager.getComponent<Ice::CameraComponent>(m_terrainEnt);
        auto pBiomeSystem = entityManager.getSystem<BiomeSystem, true>();

        InputReceiverComponent inp;
        inp.m_vKeyboardHandlers.emplace_back([this, &camera=camComp](Entity e, std::uint32_t event_type, SDL_KeyboardEvent* pEvent) {
            switch (event_type) {
                case SDL_KEYDOWN:
                    switch (pEvent->keysym.sym) {
                        case SDLK_ESCAPE:
                            return false;
                       case SDLK_l:
                            systemServices.getGraphicsSystem()->toggleWireframe();
                            break;
                        default:
                            break;
                    }
                default:
                    break;
            }
            return true;
        });
        inp.m_vMouseHandlers.emplace_back([this,&mainCamera,pBiomeSystem](Entity e, std::uint32_t event, SDL_MouseMotionEvent* pMotion, SDL_MouseButtonEvent* pButton, SDL_MouseWheelEvent* pWheel) {

            if (pButton->type == SDL_MOUSEBUTTONDOWN && pButton->button == SDL_BUTTON_LEFT) {

                std::pair<int, int> tilePair;
                const TerrainComponent& terr = entityManager.getComponent<TerrainComponent>(m_terrainEnt);
                const auto& cam = entityManager.getComponent<Ice::CameraComponent>(m_terrainEnt);
                //tilePair = terr.getSelectedTile(cam.m_camera, 1.0f, 1);
                //if (tilePair != std::make_pair(-1, -1))
                //    systemServices.getEventQueue()->queueEvent(Event{ EventId::TERRAIN_TILE_SELECTED_EVENT, TerrainTileSelectedEventArgs{ tilePair.first, tilePair.second, terr } });

            } else if (pMotion->xrel != 0 || pMotion->yrel != 0) {
                const auto& cam = entityManager.getComponent<Ice::CameraComponent>(m_terrainEnt);
                MousePicker p{ pMotion->x, pMotion->y, cam.m_camera.matrix() };
                auto dir = p.getMouseRay(); 
                Ray ray{ cam.m_camera.position(), dir };
                auto res = this->m_pTerrainSys->intersects(this->m_terrainEnt, ray);
                if (!res.bIntersects)
                    return true;

                const auto& arBiomes = pBiomeSystem->getBiomesAt(res.triangle, res.barycentric);
                
                int nCnt{};
                glm::ivec2 p1{ res.point.x * 1.0f/15.0f, res.point.z * 1.0f/15.0f };
                std::cout << "Mouse at " << glm::to_string(p1) << ":\n";
                for (const auto& [b, fValue] : arBiomes) {
                    if (b != BiomeType::NONE) {
                        std::cout << "\tBiome[" << nCnt++ << "] is ";
                        switch (b) {
                            case BiomeType::GRASSLAND:
                                std::cout << "GRASSLAND";
                                break;
                            case BiomeType::SNOW:
                                std::cout << "SNOW";
                                break;
                            default:
                                std::cout << "NONE";
                                break;
                        }
                        std::cout << " with strength " << fValue << std::endl;
                    }
                }
 
            }
            return true;
		});

        entityManager.addComponent(m_terrainEnt, inp);

        auto& terr = entityManager.getComponent<TerrainComponent>(m_terrainEnt);

        std::map<std::string, MeshComponent> mMeshes;
        RenderMaterialsComponent mat;

        auto treeModel = ModelImporterOBJ{ AssetFile{ "Tree.obj"} };
        mMeshes.clear();
        treeModel.import(mMeshes);
        mat.materials() = treeModel.materials();
        auto treeEnt = entityManager.createEntity();
        entityManager.addComponent(treeEnt, mMeshes.begin()->second);
        entityManager.addComponent(treeEnt, mat);
        const auto& terrainComp = entityManager.getComponent<TerrainComponent>(m_terrainEnt);
        glm::vec2 XZ{};
                XZ = m_pTerrainSys->getCenterCoordsForTile(terr, 9, 11);
                glm::mat4 matTerrain;
                auto fHeight = m_pTerrainSys->getHeight(XZ.x, XZ.y, &matTerrain);
        entityManager.addComponent(treeEnt, TransformComponent{ matTerrain });
        

        entityManager.addComponent(treeEnt, ModelInstanceTagComponent{});
        entityManager.addComponent(treeEnt, ModelReferenceComponent{ treeEnt });

        auto tuftModel = ModelImporterOBJ{ AssetFile{ "tuftGrass.obj"} };
        mMeshes.clear();
        tuftModel.import(mMeshes);
        mat.materials() = tuftModel.materials();
        auto tuftEnt = entityManager.createEntity();
        entityManager.addComponent(tuftEnt, mMeshes.begin()->second);
        entityManager.addComponent(tuftEnt, mat);
        entityManager.addComponent(tuftEnt, SaveComponent{});       
        auto pSave = entityManager.getSystem<Ice::SaveSystem, false>();
        std::ofstream f2{ AssetFile { "Blueprints/tuftGrass.txt" } };
        nlohmann::json j2;
        pSave->save(j2, tuftEnt);
        f2 << j2.dump(2) << std::endl;
        f2.close();

 
        /*
        auto biomeEnt = entityManager.createEntity();
        auto biomeTransform = TransformComponent{};
        biomeTransform.m_transform = glm::translate(glm::mat4{1.0f}, glm::vec3{ 150.f, m_pTerrainSys->getHeight(150.0f, 170.0f), 170.0f });
        entityManager.addComponent(biomeEnt, biomeTransform);
        entityManager.addComponent(biomeEnt, BiomeNodeComponent{ 1, BiomeType::SNOW, RGBA( 255, 255, 255 ), 0.0_pct, 200.0f, BiomeNodeComponent::State::EXPANDING });
        */

        auto biomeEnt2 = entityManager.createEntity();
        auto biomeTransform = TransformComponent{};
        biomeTransform.m_transform = glm::translate(glm::mat4{1.0f}, glm::vec3{ 150.f, m_pTerrainSys->getHeight(150.0f, 520.0f), 520.0f });
        entityManager.addComponent(biomeEnt2, biomeTransform);
            //Ice::
        //entityManager.addComponent(biomeEnt2, BiomeNodeComponent{ BiomeType::SNOW, RGBA( 255, 255, 255 ), 100.0_pct, 200.0f });
        entityManager.addComponent(biomeEnt2, BiomeNodeComponent{ 2, BiomeType::GRASSLAND, RGBA( 36, 201, 130 ), 100.0_pct, 200.0f });

        auto pBeeSystem = entityManager.getSystem<BeeSystem, true>();
        auto beeModel = ModelImporterOBJ{ AssetFile{ "Bee.obj"} };
        mMeshes.clear();
        beeModel.import(mMeshes);
        mat.materials() = beeModel.materials();
        auto beeEnt = pBeeSystem->createBee(2);
        auto& beeComp = entityManager.getComponent<BeeComponent>(beeEnt);
        beeComp.bindTransform = glm::scale(glm::mat4{1.0f}, glm::vec3{5.0f,5.0f,5.0f});
        entityManager.addComponent(beeEnt, mMeshes.begin()->second);
        entityManager.addComponent(beeEnt, mat);
                XZ = m_pTerrainSys->getCenterCoordsForTile(terr, 10, 11);
                fHeight = m_pTerrainSys->getHeight(XZ.x, XZ.y, &matTerrain);
        entityManager.addComponent(beeEnt, TransformComponent{ matTerrain });

        entityManager.addComponent(beeEnt, ModelInstanceTagComponent{});
        entityManager.addComponent(beeEnt, ModelReferenceComponent{ beeEnt });

        Ice::Entity manEntComp;
        if (!std::filesystem::exists(std::string{ AssetFile{ "Blueprints/character.txt"} }))
        {
            manEntComp = AnimatedModelRenderingSystem::loadBlueprintFromExternalFile(AssetFile{ "astronaut animated.gltf" });
            /*
            Ice::ModelImporterGlTF gltf{ AssetFile{ "adam2.gltf" } };
            gltf.import();
            manEntComp = entityManager.createEntity();
            entityManager.addComponent(manEntComp, gltf.meshes().begin()->second);
            auto& meshCompAni = entityManager.getComponent<MeshComponent>(manEntComp);
            meshCompAni.shaderId() = "AnimatedModel";
            entityManager.addComponent(manEntComp, gltf.animatedMeshes().begin()->second);
            entityManager.addComponent(manEntComp, gltf.skeletonComponents().begin()->second);
            entityManager.addComponent(manEntComp, ModelAnimationComponent { gltf.animations().at("Run") });

            RenderMaterialsComponent mat;
            mat.materials() = gltf.materials();
            entityManager.addComponent(manEntComp, mat);
            */
            {
                auto pSave = entityManager.getSystem<Ice::SaveSystem, false>();
                std::ofstream f2{ AssetFile { "Blueprints/character.txt" } };
                nlohmann::json j2;
                pSave->save(j2, manEntComp);
                f2 << j2.dump(2) << std::endl;
                f2.close();
            }

       } else {
            const auto vEnts = componentManager->loadEntityFileJson(std::string{ AssetFile{ "Blueprints/character.txt"}});
            manEntComp = vEnts.front();
            assert(entityManager.hasComponent<SkeletonComponent>(manEntComp) 
                && entityManager.hasComponent<ModelAnimationComponent>(manEntComp)
                && entityManager.hasComponent<MeshComponent>(manEntComp)
                && entityManager.hasComponent<AnimatedMeshComponent>(manEntComp)
                && entityManager.hasComponent<RenderMaterialsComponent>(manEntComp));
 
        }
        XZ = m_pTerrainSys->getCenterCoordsForTile(terr, 8, 8);
        fHeight = m_pTerrainSys->getHeight(XZ.x, XZ.y, &matTerrain);
        auto manInst = AnimatedModelRenderingSystem::createInstance(manEntComp, matTerrain);
        auto& manInstAniComp = entityManager.getComponent<ModelAnimationComponent>(manInst);
        manInstAniComp.pCurrent = &manInstAniComp.animations["Idle"];
        XZ = m_pTerrainSys->getCenterCoordsForTile(terr, 1, 0);
        fHeight = m_pTerrainSys->getHeight(XZ.x, XZ.y, &matTerrain);
        auto manInst2 = AnimatedModelRenderingSystem::createInstance(manEntComp, matTerrain);
        auto& manInstAniComp2 = entityManager.getComponent<ModelAnimationComponent>(manInst2);
        manInstAniComp2.pCurrent = &manInstAniComp.animations["Idle"];

        // TASKS FOR CHARACTER
        CharacterComponent charComp;
        charComp.actions.push_back(CharacterComponent::Action::WALK);
        charComp.actions.push_back(CharacterComponent::Action::PLACE_BIOME_NODE);
        entityManager.addComponent(manInst, charComp);
        WalkActionComponent act;
        act.target = glm::vec2{ 150.0f, 170.0f };
        entityManager.addComponent(manInst, act);
        entityManager.addComponent(manInst, PlaceBiomeNodeActionComponent{ BiomeType::SNOW });
        

        std::random_device rd;
        std::mt19937 gen{rd()};
        std::uniform_real_distribution<> dist{ 0.0f, 64 * 15.0f };
        for (int i = 0; i < 9000; ++i) {
            auto tuftInst = entityManager.createEntity();
            m_pTerrainSys->getHeight(dist(gen), dist(gen), &matTerrain);
            entityManager.addComponent(tuftInst, TransformComponent{ matTerrain * glm::scale( glm::mat4{1.0f}, glm::vec3{ 3.0f, 3.0f, 3.0f }) });
            entityManager.addComponent(tuftInst, ModelInstanceTagComponent{});
            entityManager.addComponent(tuftInst, ModelReferenceComponent{ tuftEnt });
            glm::vec2 pos{ matTerrain[3][0], matTerrain[3][2]};
       }

        
        auto pWaterSystem = entityManager.getSystem<WaterRenderingSystem, true>();
        pWaterSystem->setWaterLevel(m_fTerrainMinHeight + 25.0f);
        pWaterSystem->setGridSize(TERRAIN_TILE_SIZE);
        auto water = entityManager.createEntity();
        WaterTileComponent waterComp { { glm::vec2 { 0.0f, 0.0f }, TERRAIN_SIZE, TERRAIN_SIZE, TERRAIN_TILE_SIZE, TERRAIN_TILE_SIZE }};
        entityManager.addComponent(water, waterComp);
      
        auto sun = entityManager.createEntity();
	    entityManager.addComponent(sun, SunComponent{});

        auto pEventSys = entityManager.getSystem<EventHandlingSystem, false>();
        pEventSys->setCameraEnt(m_terrainEnt);
        /*
        m_pChanger = dynamic_cast<Ice::IContrastChanger*>(entityManager.getSystem<MasterRenderingSystem, false>()->addPostProcessingEffect(PostProcessingEffect::CONTRAST_CHANGER));
        m_pHorGauss = dynamic_cast<Ice::IGaussianBlur*>(entityManager.getSystem<MasterRenderingSystem, false>()->addPostProcessingEffect(PostProcessingEffect::HORIZONTAL_GAUSSIAN_BLUR));
        m_pVerGauss = dynamic_cast<Ice::IGaussianBlur*>(entityManager.getSystem<MasterRenderingSystem, false>()->addPostProcessingEffect(PostProcessingEffect::VERTICAL_GAUSSIAN_BLUR));
        m_pHorGauss->setKernelSize(24);
        m_pVerGauss->setKernelSize(24);
        */
   }
}