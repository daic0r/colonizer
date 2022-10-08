#include <Engine.h>
#include <System/Config.h>
#include "Colonizer.h"

int main(int argc, const char* argv[]) {
    using namespace Ice;

    Config cfg{ 1980, 1020, false, 0, 0, "Data/Assets/", PathType::RELATIVE_PATH, "Data/", PathType::RELATIVE_PATH };
    cfg.setGameName("Colonizer");
    cfg.camera().m_fMaxDistance = 500.0f;

    std::vector<Ice::SystemId> ids = { SystemId::DAY_NIGHT, SystemId::BIOME, SystemId::BEE, SystemId::CHARACTER };
    cfg.setSystemIds(ids);

    Engine e{};
    auto pGame = std::make_unique<Colonizer::Colonizer>();
    auto pLoader = pGame.get();
    if (!e.init(cfg, pLoader, std::move(pGame)))
        return -1;

    e.run();

    return 0;
}