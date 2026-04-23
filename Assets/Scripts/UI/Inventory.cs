using System.Collections.Generic;
using UnityEngine;

public class Inventory : MonoBehaviour
{
    [SerializeField] private List<UIItemInventorySlot> _inventorySlots = new();
    [SerializeField] private DroppedItem _droppedItemPrefab;
    [SerializeField] private Character _character;
    [SerializeField] private Color _greenColor, _redColor;

    private UIItemInventorySlot _highlightedSlot;

    private void Awake()
    {
        foreach (var slot in _inventorySlots)
        {
            slot.InitializeSlot(this);
        }
    }

    public void DropItem(Item item)
    {
        var dropItem = Instantiate(_droppedItemPrefab, _character.transform.position + Vector3.up * 0.5f, Quaternion.Euler(60f, 0f, 0f));
        dropItem.InitializeItem(this, item);
    }

    public void NotifySlotChanged(UIItemInventorySlot slot, Item item)
    {
        if (slot.GetSlotType() == InventorySlotType.WeaponFirst)
        {
            _character.WeaponEquipped(item);
        }
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

    public void Highlight(UIItemInventorySlot slot, bool canBePlaced)
    {
        if (slot.Equals(_highlightedSlot)) return;

        if(_highlightedSlot != null)
        {
            _highlightedSlot.HighlightSlot(false, canBePlaced == true ? _greenColor : _redColor);
        }

        _highlightedSlot = slot;
        _highlightedSlot.HighlightSlot(true, canBePlaced == true ? _greenColor : _redColor);
    }

    public void CancelHighlight()
    {
        _highlightedSlot?.HighlightSlot(false, _greenColor);
        _highlightedSlot = null;
    }
}
