using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using Zenject;

public class DroppedItem : MonoBehaviour, IPointerClickHandler
{
    [SerializeField] private Item _item;
    [SerializeField] private TextMeshPro _itemName;

    private InventoryService _inventory;

    public void Construct(InventoryService inventory)
    {
        _inventory = inventory;
    }

    private void Awake()
    {
        _itemName.text = _item.Name;
    }

    public void InitializeItem(Item item)
    {
        _item = item;
        _itemName.text = _item.Name;
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if(_inventory == null)
        {
            _inventory = FindFirstObjectByType<InventoryService>(FindObjectsInactive.Include);
        }
        _inventory.TryPutItemToInventory(this);
    }

    public EquippedWeaponType GetWeaponType() => _item.WeaponType;
    public Item GetItemInfo() => _item;
}
