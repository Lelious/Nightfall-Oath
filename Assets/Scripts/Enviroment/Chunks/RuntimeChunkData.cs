using System.Collections.Generic;

public class RuntimeChunkData
{
    public List<RuntimeChunkObject> RuntimeObjects;

    public RuntimeChunkData(List<MapCreatureInfo> dynamicInfo)
    {
        RuntimeObjects = new();

        foreach (var item in dynamicInfo)
        {
            RuntimeObjects.Add(new RuntimeChunkObject(item));
        }
    }
}

public class RuntimeChunkObject
{
    public MapCreatureInfo DynamicObject;
    public bool Alive;
    public float ActiveHealth;
    public float RessurectedTime; //Experimental

    public RuntimeChunkObject(MapCreatureInfo info)
    {
        DynamicObject = info;
        Alive = true;
    }
}
