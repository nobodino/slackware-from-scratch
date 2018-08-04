#/bin/sh
# nvidia-settings fsaa for nvidia proprietary tool to have full fonctionality activated
nvidia-settings --assign FSAA=5 --assign FSAAAppControlled=1 --assign FSAAAppEnhanced=1 --assign="SyncToVBlank=0"
