using UnityEngine;
using Zenject;

public class BootstrapInstaller : MonoInstaller
{
    public override void InstallBindings()
    {
        BindPool();
    }

    private void BindPool()
    {
        Container.
             BindInterfacesAndSelfTo<PoolService>().
             AsSingle().
             NonLazy();
    }
}
