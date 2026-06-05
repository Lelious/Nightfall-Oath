using Cysharp.Threading.Tasks;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AddressableAssets;
using Zenject;

public class EnemyFactory
{
    private Dictionary<byte, CreatureObject> _cache;
    private PoolService _poolService;

    [Inject]
    public void Construct(PoolService poolService)
    {
        _poolService = poolService;
        _cache = new();
        FillCache().Forget();
    }

    public async UniTask CreateEnemy(IMapCreature creature, MapCreatureInfo info)
    {    
        var creatureView = await CreateCreatureView(info.CreatureType, creature.Transform());
        var runtimeData = new EnemyRuntimeData(_cache[info.CreatureType].Data, info.Level, info.Elite);
        creature.InitializeCreature(runtimeData, creatureView);
    }

    public void DestroyEnemy(IMapCreature creature)
    {
        Addressables.ReleaseInstance(creature.GetCreatureView());

        _poolService.ReturnToPool(creature);
    }

    private async UniTask FillCache()
    {
        var creatureDatabase = await Addressables.LoadAssetAsync<CreatureDatabase>(AssetPath.CreatureDatabase).ToUniTask();

        foreach (var item in creatureDatabase.prefabs)
        {
            _cache[item.ID] = item;
        }

        Addressables.Release(creatureDatabase);
    }

    private async UniTask<GameObject> CreateCreatureView(byte type, Transform parent)
    {
        return await Addressables.InstantiateAsync(_cache[type].Data.AssetAddress, parent).ToUniTask();
    }
}
