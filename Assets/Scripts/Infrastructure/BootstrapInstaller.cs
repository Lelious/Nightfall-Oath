using Zenject;

public class BootstrapInstaller : MonoInstaller
{   
    public override void InstallBindings()
    {
        BindPool();
        BindInputService();
        BindLightService();
        BindTargetingService();
        BindSceneInitializer();
        BindEnemyFactory();
        BindWorldGraphicStreamService();
    }

    private void BindPool()
    {
        Container
            .Bind<PoolService>()
            .AsSingle();
    }

    private void BindTargetingService()
    {
        Container
            .Bind<TargetingService>()
            .AsSingle()
            .NonLazy();
    }

    private void BindSceneInitializer()
    {
        Container
            .BindInterfacesAndSelfTo<SceneInitializerService>()
            .AsSingle()
            .NonLazy();
    }

    private void BindLightService()
    {
        Container
            .BindInterfacesAndSelfTo<CustomLightService>()
            .AsSingle()
            .NonLazy();
    }

    private void BindEnemyFactory()
    {
        Container
            .BindInterfacesAndSelfTo<EnemyFactory>()
            .AsSingle()
            .NonLazy();
    }

    private void BindInputService()
    {
        Container
            .Bind<InputService>()
            .AsSingle();
    }

    private void BindWorldGraphicStreamService()
    {
        Container
            .BindInterfacesAndSelfTo<WorldGraphicStreamService>()
            .AsSingle()
            .NonLazy();
    }
}
