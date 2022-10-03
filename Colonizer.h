#include <Interfaces/IGame.h>
#include <Interfaces/ILoader.h>
#include <Entities/Entity.h>
#include <World/World.h>
#include <optional>
#include <map>
#include <memory>

namespace Ice {
    class IContrastChanger;
    class IGaussianBlur;
    class TerrainSystem;
}

namespace Colonizer {

    class Colonizer : public Ice::IGame, public Ice::ILoader {
        static constexpr auto TERRAIN_TILE_SIZE = 15.0f;
        static constexpr auto TERRAIN_SIZE = 64;

        void generateTerrain();
        void initGUI();

    public:
        Colonizer() = default; 
        void update(float fDeltaTime, Ice::IEventQueue*) noexcept override;
        void init() override;
        bool loadData() override;

    private:
        float m_fTerrainMinHeight{}; 
        std::optional<Ice::World> m_world;
        Ice::IContrastChanger *m_pChanger{};
        Ice::IGaussianBlur *m_pHorGauss;
        Ice::IGaussianBlur *m_pVerGauss;
        Ice::TerrainSystem* m_pTerrainSys{};
        Ice::Entity m_terrainEnt;
    };
}