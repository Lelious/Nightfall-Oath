using System;
using UnityEngine;
using Zenject;
using Cysharp.Threading.Tasks;
using UnityEngine.AddressableAssets;
using System.Collections.Generic;
using UnityEngine.ResourceManagement.AsyncOperations;

public class SceneInitializerService : IInitializable, IDisposable
{
    private readonly List<GameObject> _spawnedInstances = new();
    private readonly List<AsyncOperationHandle> _assetHandles = new();
    private readonly DiContainer _container;
    private IInstantiator _instantiator;

    public SceneInitializerService(DiContainer container, IInstantiator instantiator)
    {
        _instantiator = instantiator;
        _container = container;
    }

    public async void Initialize()
    {
        var navMeshHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.NavMeshBuilder);
        var chunkHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.ChunkGenerator);
        var heroHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.CharacterMale);
        var cameraHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.CameraService);
        var playerHUDHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.PlayerHUD);
        var interfaceUiHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.InterfaceUI);
        var screenTargetHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.ScreenTargetSelector);
        var floatingTextHandle = Addressables.LoadAssetAsync<GameObject>(AssetPath.FloatingTextService);

        _assetHandles.AddRange(new AsyncOperationHandle[]
        {
            navMeshHandle, chunkHandle, heroHandle, cameraHandle, playerHUDHandle, interfaceUiHandle, screenTargetHandle, floatingTextHandle
        });

        var (navMeshPrefab, chunkPrefab, heroPrefab, cameraPrefab, playerHUDPrefab, interfaceUiPrefab, screenTargetPrefab, floatingTextPrefab) =
            await UniTask.WhenAll(
                navMeshHandle.ToUniTask(),
                chunkHandle.ToUniTask(),
                heroHandle.ToUniTask(),
                cameraHandle.ToUniTask(),
                playerHUDHandle.ToUniTask(),
                interfaceUiHandle.ToUniTask(),
                screenTargetHandle.ToUniTask(),
                floatingTextHandle.ToUniTask()
            );

        var floatingTextObj = _instantiator.InstantiatePrefab(floatingTextPrefab);
        var floatingTextService = floatingTextObj.GetComponent<FloatingTextService>();

        _container.BindInstance(floatingTextService).AsSingle().NonLazy();
        _container.Bind<DamageProcessService>().AsSingle();

        var cameraObj = _instantiator.InstantiatePrefab(cameraPrefab);
        var heroObj = _instantiator.InstantiatePrefab(heroPrefab);
        var hero = heroObj.GetComponent<Character>();
        _container.BindInstance(hero).AsSingle();

        InitGameLogic(hero, cameraObj);

        _container.Bind<InGameHUDViewModel>().AsSingle();

        var playerHUDobj = _instantiator.InstantiatePrefab(playerHUDPrefab);
        var playerHUD = playerHUDobj.GetComponent<PlayerHUD>();
        _container.BindInstance(playerHUD).AsSingle();

        var bottomPanelObj = _instantiator.InstantiatePrefab(interfaceUiPrefab);
        var bottomPannel = bottomPanelObj.GetComponent<BottomPannelService>();
        _container.BindInstance(bottomPannel).AsSingle();

        var navMeshBuilderObj = _instantiator.InstantiatePrefab(navMeshPrefab);
        var navMeshBuilder = navMeshBuilderObj.GetComponent<NavMeshBuilderService>();
        _container.BindInstance(navMeshBuilder).AsSingle().NonLazy();

        var chunkGeneratorObj = _instantiator.InstantiatePrefab(chunkPrefab);
        var chunkGenerator = chunkGeneratorObj.GetComponent<ChunkGenerator>();
        _container.BindInstance(chunkGenerator).AsSingle();

        var screenTargetObj = _instantiator.InstantiatePrefab(screenTargetPrefab);
        var screenTargetSelector = chunkGeneratorObj.GetComponent<ScreenTargetSelector>();
        _container.BindInstance(screenTargetSelector).AsSingle();

        _spawnedInstances.AddRange(new[]
        {
            playerHUDobj, bottomPanelObj, cameraObj, heroObj, navMeshBuilderObj, chunkGeneratorObj, screenTargetObj
        });     
    }

    private void InitGameLogic(Character hero, GameObject camera)
    {
        if (camera.TryGetComponent<PlayerCameraController>(out var controller))
            controller.SetHeroTransform(hero.transform);
    }

    public void Dispose()
    {
        foreach (var instance in _spawnedInstances)
        {
            if (instance != null)
            {
                UnityEngine.Object.Destroy(instance);
            }
        }
        _spawnedInstances.Clear();

        foreach (var handle in _assetHandles)
        {
            if (handle.IsValid())
            {
                Addressables.Release(handle);
            }
        }
        _assetHandles.Clear();
    }
}
