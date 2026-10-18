#!/usr/bin/env python3
import json
import os
import subprocess
import sys

def get_active_mpris_player():
    try:
        players = subprocess.check_output(['playerctl', '-l'], text=True).strip().splitlines()
        for p in players:
            try:
                status = subprocess.check_output(['playerctl', '-p', p, 'status'], text=True).strip()
                if status == 'Playing':
                    return p
            except Exception:
                pass
        if players:
            return players[0]
    except Exception:
        pass
    return "spotify"

def focus_window_for_player(mpris_name):
    mpris_lower = mpris_name.lower()
    
    # 1. Query Hyprland clients
    clients = []
    try:
        out = subprocess.check_output(['hyprctl', 'clients', '-j'], text=True)
        clients = json.loads(out)
    except Exception:
        pass

    target_window = None

    for c in clients:
        cls = c.get('class', '')
        cls_lower = cls.lower()
        title = c.get('title', '')
        title_lower = title.lower()
        
        # Check matching player keywords
        if ('spotify' in mpris_lower and ('spotify' in cls_lower or 'spotify' in title_lower)) or \
           (('zen' in mpris_lower or 'browser' in mpris_lower or 'youtube' in title_lower or 'music' in title_lower) and ('zen' in cls_lower or 'firefox' in cls_lower or 'chrome' in cls_lower)) or \
           ('firefox' in mpris_lower and 'firefox' in cls_lower) or \
           ('rhythmbox' in mpris_lower and 'rhythmbox' in cls_lower) or \
           ('vlc' in mpris_lower and 'vlc' in cls_lower):
            target_window = c
            break

    if target_window:
        workspace_id = target_window.get('workspace', {}).get('id')
        cls_name = target_window.get('class')
        title_name = target_window.get('title')

        # Switch workspace & focus window using hyprlua
        if workspace_id is not None:
            try:
                subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.focus({{ workspace = {workspace_id} }})'], stderr=subprocess.DEVNULL)
            except Exception:
                pass

        if cls_name:
            try:
                res = subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.focus({{ window = "class:{cls_name}" }})'], capture_output=True, text=True)
                if 'ok' in res.stdout:
                    return True
            except Exception:
                pass

        try:
            if cls_name:
                subprocess.run(['wmctrl', '-x', '-a', cls_name], stderr=subprocess.DEVNULL)
            if title_name:
                subprocess.run(['wmctrl', '-a', title_name], stderr=subprocess.DEVNULL)
        except Exception:
            pass
        return True

    # General fallback
    search_term = "spotify"
    if "zen" in mpris_lower: search_term = "zen"
    elif "firefox" in mpris_lower: search_term = "firefox"
    elif "rhythmbox" in mpris_lower: search_term = "rhythmbox"
    elif "vlc" in mpris_lower: search_term = "vlc"

    try:
        subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.focus({{ window = "class:{search_term}" }})'], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    try:
        res = subprocess.run(['wmctrl', '-x', '-a', search_term], stderr=subprocess.DEVNULL)
        if res.returncode == 0:
            return True
    except Exception:
        pass

    try:
        subprocess.Popen([search_term])
    except Exception:
        pass
    return False

if __name__ == '__main__':
    player = get_active_mpris_player()
    focus_window_for_player(player)
