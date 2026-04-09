using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class UIItemInventorySlot : MonoBehaviour, IBeginDragHandler, IEndDragHandler, IDragHandler, IPointerClickHandler
{
    [SerializeField] private Canvas _canvas;
    [SerializeField] private RectTransform _dragParent;
    [SerializeField] private DraggedItem _itemDragPrefab;
    [SerializeField] private Image _itemImage;
    [SerializeField] private Image _slotRarity;
    [SerializeField] private Sprite _defaultSlotImage;

    private Inventory _inventory;
    private Item _item;
    private bool _isEmptySlot = true;
    private DraggedItem _draggedItem;

    public bool IsEmpty() => _isEmptySlot;
    public Item GetSlotItem() => _item;

    public void InitializeSlot(Inventory inventory)
    {
        _inventory = inventory;
    }

    public void SetItemToSlot(Item droppedItem)
    {
        _item = droppedItem;
        _itemImage.sprite = _item.Icon;
        _slotRarity.sprite = _item.Rarity;
        _isEmptySlot = false;
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
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        if (_draggedItem == null) return;

        var results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(eventData, results);

        InventoryArea area = null;

        foreach (var result in results)
        {
            if(result.gameObject.TryGetComponent(out UIItemInventorySlot slot))
            {
                if(slot.Equals(this))
                {
                    RemoveDraggedObject();

                    return;
                }
                else
                {
                    var item = slot.GetSlotItem();
                    slot.SetItemToSlot(_item);

                    if (item != null)
                    {
                        SetItemToSlot(item);
                    }
                    else
                    {                      
                        ClearItemSlot();
                    }
                    RemoveDraggedObject();

                    return;
                }
            }
            else if(result.gameObject.TryGetComponent(out area))
            {
                RemoveDraggedObject();
            }
        }

        if(area == null)
        {
            _inventory.DropItem(_item);
            ClearItemSlot();
            RemoveDraggedObject();
        }
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        throw new System.NotImplementedException();
    }

    public void RemoveDraggedObject()
    {
        if (_draggedItem == null) return;

        Destroy(_draggedItem.gameObject);
    }

    private void ClearItemSlot()
    {
        _item = null;
        _itemImage.sprite = _defaultSlotImage;
        _slotRarity.sprite = _defaultSlotImage;
        _isEmptySlot = true;
    }
}
