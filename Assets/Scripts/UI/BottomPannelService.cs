using UnityEngine;
using UnityEngine.UI;

public class BottomPannelService : MonoBehaviour
{
    [SerializeField]
    private Button _inventoryBottomButton,
                   _skillsAndTallentsButton,
                   _questLogButton,
                   _closeButton;

    [SerializeField]
    private GameObject _inventoryWindow,
                       _skillsAndTallentsWindow,
                       _questLogWindow,
                       _infoWindow;

    private GameObject _previousOpenedWindow; 

    private void Awake()
    {
        _inventoryBottomButton.onClick.AddListener(delegate { OpenWindow(_inventoryWindow); });
        _skillsAndTallentsButton.onClick.AddListener(delegate { OpenWindow(_skillsAndTallentsWindow); });
        _questLogButton.onClick.AddListener(delegate { OpenWindow(_questLogWindow); });
        _closeButton.onClick.AddListener(CloseAllWindows);
    }

    private void OpenWindow(GameObject window)
    {
        if(!_infoWindow.activeInHierarchy)
        {
            _infoWindow.SetActive(true);
        }

        if(window.Equals(_previousOpenedWindow))
        {
            if(_previousOpenedWindow.activeInHierarchy)
            {
                CloseAllWindows();
            }
        }
        else
        {
            _previousOpenedWindow?.SetActive(false);
            window.SetActive(true);
            _previousOpenedWindow = window;
        }
    }

    private void CloseAllWindows()
    {
        _previousOpenedWindow?.SetActive(false);
        _previousOpenedWindow = null;
        _infoWindow.SetActive(false);
    }
}
