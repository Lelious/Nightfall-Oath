using System.Collections.Generic;
using UnityEngine;

public class Inventory : MonoBehaviour
{
    [SerializeField] private List<UIItemInventorySlot> _inventorySlots = new();
    [SerializeField] private DroppedItem _droppedItemPrefab;
    [SerializeField] private Transform _hero;
    
    private void Awake()
    {
        foreach (var slot in _inventorySlots)
        {
            slot.InitializeSlot(this);
        }
    }

    public void DropItem(Item item)
    {
        var dropItem = Instantiate(_droppedItemPrefab, _hero.position + Vector3.up * 0.5f, Quaternion.Euler(60f, 0f, 0f));
        dropItem.InitializeItem(this, item);
    }

    public void TryPutItemToInventory(DroppedItem droppedItem)
    {
        foreach (var slot in _inventorySlots)
        {
            if(slot.IsEmpty())
            {
                slot.SetItemToSlot(droppedItem.GetItemInfo());
                Destroy(droppedItem.gameObject);
                return;
            }
        }
    }
}
