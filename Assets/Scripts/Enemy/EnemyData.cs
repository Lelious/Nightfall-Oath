using UnityEngine;

[CreateAssetMenu(fileName = "EnemyData", menuName = "ScriptableObjects/EnemyData", order = 1)]
public class EnemyData : ScriptableObject
{
    public string Name;
    public int Level;
    public int Health;
    public bool Elite;
    public float FrameScale;
}
