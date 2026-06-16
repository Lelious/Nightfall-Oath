using System.Collections.Generic;

public class RuntimeChunkData
{
    public List<RuntimeCreatureState> RuntimeDynamicObjects;
    public List<RuntimeInteractiveState> RuntimeInteractiveObjects;

    public RuntimeChunkData(List<MapCreatureInfo> dynamicInfo, List<MapObjectInfo> interactiveInfo)
    {
        RuntimeDynamicObjects = new();
        RuntimeInteractiveObjects = new();

        foreach (var item in dynamicInfo)
        {
            RuntimeDynamicObjects.Add(new RuntimeCreatureState(item));
        }

        foreach (var item2 in interactiveInfo)
        {
            RuntimeInteractiveObjects.Add(new RuntimeInteractiveState(item2));
        }
    }
}

public abstract class RuntimeChunkObject
{
    public MapObjectInfo TargetObject { get; protected set; }

    protected RuntimeChunkObject(MapObjectInfo info)
    {
        TargetObject = info;
    }
}

public class RuntimeCreatureState : RuntimeChunkObject
{
    public bool Alive;
    public float ActiveHealth;
    public float RessurectedTime;

    public MapCreatureInfo CreatureInfo => (MapCreatureInfo)TargetObject;

    public RuntimeCreatureState(MapCreatureInfo info) : base(info)
    {
        Alive = true;
    }
}

public class RuntimeInteractiveState : RuntimeChunkObject
{
    public byte State;
    public float LastActivationTime;

    public RuntimeInteractiveState(MapObjectInfo info) : base(info)
    {
        State = 0;
    }
}
