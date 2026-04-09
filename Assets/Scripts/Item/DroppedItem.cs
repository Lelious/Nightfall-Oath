using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;

public class DroppedItem : MonoBehaviour, IPointerClickHandler
{
    [SerializeField] private Inventory _inventory;
    [SerializeField] private Item _item;
    [SerializeField] private TextMeshPro _itemName;

    private void Awake()
    {
        _itemName.text = _item.Name;
    }

    public void InitializeItem(Inventory inventory, Item item)
    {
        _inventory = inventory;
        _item = item;
        _itemName.text = _item.Name;
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        _inventory.TryPutItemToInventory(this);
    }

    public Item GetItemInfo() => _item;
}
