using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class UIItemInventorySlot : MonoBehaviour, IBeginDragHandler, IEndDragHandler, IDragHandler, IPointerClickHandler
{
    [SerializeField] private RectTransform _dragParent;
    [SerializeField] private DraggedItem _itemDragPrefab;
    [SerializeField] private Image _itemImage;
    [SerializeField] private Image _slotRarity;
    [SerializeField] private Sprite _defaultSlotImage;
    [SerializeField] private InventorySlotType _slotType;
    [SerializeField] private Image _highlight;

    private InventoryService _inventory;
    private Item _item;
    private bool _isEmptySlot = true;
    private DraggedItem _draggedItem;
    private Canvas _canvas;

    public bool IsEmpty() => _isEmptySlot;
    public Item GetSlotItem() => _item;

    public void InitializeSlot(InventoryService inventory, Canvas canvas)
    {
        _inventory = inventory;
        _canvas = canvas;

        if (!_slotType.Equals(InventorySlotType.Bag))
        {
            _inventory.NotifySlotChanged(this, _item);
        }
    }

    public void SetItemToSlot(Item droppedItem)
    {
        _item = droppedItem;
        _itemImage.sprite = _item.Icon;
        _slotRarity.sprite = _item.Rarity;
        _isEmptySlot = false;

        _inventory?.NotifySlotChanged(this, _item);
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        if (_item == null) return;

        _draggedItem = Instantiate(_itemDragPrefab, eventData.position, Quaternion.identity, _dragParent);
        _draggedItem.InitializeDraggedItem(_item);
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (_draggedItem == null) return;

        _draggedItem.MoveDraggedItem(eventData.delta / _canvas.scaleFactor);
        var results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(eventData, results);

        UIItemInventorySlot slot = null;

        foreach (var result in results)
        {
            if (result.gameObject.TryGetComponent(out slot))
            {
                if (slot.Equals(this))
                {
                    _inventory.CancelHighlight();
                    return;
                }

                _inventory.Highlight(slot, CanPlaceItemInSlot(slot, _item));
                break;
            }
        }

        if(slot == null)
        {
            _inventory.CancelHighlight();
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        _inventory.CancelHighlight();

        if (_draggedItem == null) return;

        var results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(eventData, results);

        UIItemInventorySlot targetSlot = null;
        InventoryArea area = null;

        foreach (var result in results)
        {
            if (result.gameObject.TryGetComponent(out UIItemInventorySlot slot))
            {
                targetSlot = slot;
                break;
            }

            if (result.gameObject.TryGetComponent(out InventoryArea a))
            {
                area = a;
            }
        }

        if (targetSlot != null)
        {
            HandleSlotDrop(targetSlot);
            RemoveDraggedObject();
            return;
        }

        if (area != null)
        {
            RemoveDraggedObject();
            return;
        }

        _inventory.DropItem(_item);
        ClearItemSlot();
        RemoveDraggedObject();
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        throw new System.NotImplementedException();
    }

    public void RemoveDraggedObject()
    {
        if (_draggedItem == null) return;
        Debug.Log("Destroying dragged item");
        Destroy(_draggedItem.gameObject);
    }

    public void HighlightSlot(bool isEnabled, Color color)
    {
        _highlight.enabled = isEnabled;
        _highlight.color = _highlight.enabled ? color : new Color(1f, 1f, 1f, 0f); 
    }

    public InventorySlotType GetSlotType() => _slotType;

    private void HandleSlotDrop(UIItemInventorySlot targetSlot)
    {
        if (targetSlot == this) return;

        Item targetItem = targetSlot.GetSlotItem();

        bool canPlaceToTarget = CanPlaceItemInSlot(targetSlot, _item);
        bool canPlaceBack = targetItem == null || CanPlaceItemInSlot(this, targetItem);

        if (canPlaceToTarget && canPlaceBack)
        {
            targetSlot.SetItemToSlot(_item);

            if (targetItem != null)
                SetItemToSlot(targetItem);
            else
                ClearItemSlot();
        }
        else
        {

        }
    }

    private bool CanPlaceItemInSlot(UIItemInventorySlot slot, Item item)
    {
        if (slot._slotType == InventorySlotType.Bag)
            return true;

        return slot._slotType == item.SlotType;
    }

    private void ClearItemSlot()
    {
        Debug.Log("Clear item slot");
        _item = null;
        _itemImage.sprite = _defaultSlotImage;
        _slotRarity.sprite = _defaultSlotImage;
        _isEmptySlot = true;

        _inventory.NotifySlotChanged(this, null);
    }
}

public enum InventorySlotType
{
    Bag,
    WeaponFirst,
    WeaponSecond,
    Helm,
    Ring,
    Chest,
    Boot,
    Glove,
    Belt
}
