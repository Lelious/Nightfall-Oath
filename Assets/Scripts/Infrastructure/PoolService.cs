using LeliousExtentions;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class PoolService
{
    private Dictionary<ushort, Queue<IMapObject>> _mapPool;
    private Dictionary<ushort, Queue<IMapObject>> _notPersistantPool;
    private Dictionary<ushort, MapObject> _cache;
    private ObjectDatabase _database;

    public void InitializePool(ObjectDatabase database, int queueCapacity)
    {
        _mapPool = new Dictionary<ushort, Queue<IMapObject>>();
        _notPersistantPool = new Dictionary<ushort, Queue<IMapObject>>();
        _database = database;
        _cache = new Dictionary<ushort, MapObject>();

        foreach (var p in _database.prefabs)
        {
            _cache[p.ID] = p;
            Debug.Log($"Create cache {p.ID}");
        }

        foreach (var p in _database.prefabs)
        {
            if (p != null)
            {
                for (int i = 0; i < queueCapacity; i++)
                {
                    ReturnToPool(CreateObject(p.ID));
                }
            }
        }
    }

    public void ReturnToPool(IMapObject obj)
    {
        var pool = obj.PersistentObject() ? _mapPool : _notPersistantPool;

        obj.SetActive(false);

        if (Validate(pool, obj.Id()))
            pool[obj.Id()].Enqueue(obj);
        else
            InitializeNewKeyValuePair(pool, obj);
    }

    public void ClearPool()
    {
        foreach (var item in _mapPool)
        {
            var queue = _mapPool[item.Key];
            for (int i = 0; i < queue.Count; i++)
            {
                var obj = queue.Dequeue();
                GameObject.Destroy(obj.Transform().gameObject);
            }
        }
    }

    public IMapObject GetObjectFromPool(ushort id)
    {
        if (_cache.TryGetValue(id, out MapObject result))
        {
            var pool = result.Persistent ? _mapPool : _notPersistantPool;
            
            if (Validate(pool, id))
            {
                var queue = pool[id];

                if (queue.Count > 0)
                {
                    var poolObj = queue.Dequeue();
                    poolObj.SetActive(true);
                    return poolObj;
                }
                else
                    return CreateObject(id);
            }
            else
                return CreateObject(id);
        }

        else
            return null;     
    }

    public void RemoveNotPersistantFarObjects(Vector2 position, float clearDistance)
    {
        foreach (var pair in _notPersistantPool)
        {
            var queue = pair.Value;

            int count = queue.Count;

            for (int i = 0; i < count; i++)
            {
                var obj = queue.Dequeue();

                Vector3 objPos = obj.Position();

                if (LeliousMathematic.FlatDistanceGreaterThan(new Vector2(position.x, position.y),
                    new Vector2(objPos.x, objPos.z), clearDistance))
                {
                    GameObject.Destroy(obj.Transform().gameObject);
                }
                else
                {
                    queue.Enqueue(obj);
                }
            }
        }
    }

    private void InitializeNewKeyValuePair(Dictionary<ushort, Queue<IMapObject>> pool, IMapObject obj)
    {
        var queue = new Queue<IMapObject>();
        queue.Enqueue(obj);
        pool.Add(obj.Id(), queue);
    }

    private IMapObject CreateObject(ushort id)
    {
        _cache.TryGetValue(id, out MapObject result);
        var instance = GameObject.Instantiate(result.Prefab).GetComponent<IMapObject>();
        return instance;
    }

    private bool Validate(Dictionary<ushort, Queue<IMapObject>> pool, ushort id) => pool.ContainsKey(id);
}
