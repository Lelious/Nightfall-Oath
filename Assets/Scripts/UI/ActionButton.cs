using UnityEngine;
using UnityEngine.UI;

public class ActionButton : MonoBehaviour
{
    public Button Button;
    public ButtonDefaultAction ButtonDefaultAction;
    public ushort SpellId;
}

public enum ButtonDefaultAction
{
    None,
    Attack
}
