using UnityEngine;

[CreateAssetMenu(fileName = "InventoryItem", menuName = "ScriptableObjects/InventoryItem", order = 1)]
public class Item : ScriptableObject
{
    public string Name;
    public Sprite Icon;
    public Sprite Rarity;
    public float AttackDistance;
    public InventorySlotType SlotType;
    public EquippedWeaponType WeaponType;
    public GameObject Prefab;
}
