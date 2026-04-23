using UnityEngine;
using UnityEngine.UI;

public class DraggedItem : MonoBehaviour
{
    [SerializeField] private Image _backgroundImg;
    [SerializeField] private Image _itemImage;
    [SerializeField] private RectTransform _rect;

    public void InitializeDraggedItem(Item item)
    {
        _backgroundImg.sprite = item.Rarity;
        _itemImage.sprite = item.Icon;
    }

    public void MoveDraggedItem(Vector2 delta)
    {
        _rect.anchoredPosition += delta;
    }
}
