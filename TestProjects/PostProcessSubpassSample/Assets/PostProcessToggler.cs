using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessToggler : MonoBehaviour
{
    VolumeProfile volumeProfile;

    ColorAdjustments saturate;
    FilmGrain grain;
    Tonemapping tonemapping;
    Vignette vignette;

    void Start()
    {
        volumeProfile = GetComponent<UnityEngine.Rendering.Volume>()?.profile;
        if (!volumeProfile.TryGet(out saturate)) throw new System.NullReferenceException(nameof(saturate));
        if (!volumeProfile.TryGet(out grain)) throw new System.NullReferenceException(nameof(grain));
        if (!volumeProfile.TryGet(out tonemapping)) throw new System.NullReferenceException(nameof(tonemapping));
        if (!volumeProfile.TryGet(out vignette)) throw new System.NullReferenceException(nameof(vignette));
    }

    public void ToggleSaturate()
    {
        saturate.active = !saturate.active;
    }

    public void ToggleFilmGrain()
    {
        grain.active = !grain.active;
    }

    public void ToggleTonemapping()
    {
        tonemapping.active = !tonemapping.active;
    }

    public void ToggleVignette()
    {
        vignette.active = !vignette.active;
    }

}
