using UnityEngine;

public interface IMapObject
{
    public Vector3 Position();
    public Quaternion Rotation();
    public void SetActive(bool active);
    public void SetPosition(Vector3 position);
    public void SetRotation(Quaternion rotation);
    public void SetScale(Vector3 scale);
    public bool IsInitialized();
}
