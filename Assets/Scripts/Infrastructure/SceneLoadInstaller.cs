using Zenject;

public class SceneLoadInstaller : MonoInstaller
{
    public override void InstallBindings()
    {
        BindSceneLoader();
    }

    private void BindSceneLoader()
    {
        Container.
            Bind<SceneLoaderService>().
            AsSingle();
    }
}
