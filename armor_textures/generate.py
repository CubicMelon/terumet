from wand.image import Image
from wand.color import Color
from wand.drawing import Drawing

ARMORS = ['boots', 'legs', 'chest', 'helm']
PICS = ['inv', 'prv', 'arm']

BLANK = Color('rgba(0,0,0,0)')

def Replacer(color1, color2):
    draw = Drawing()
    draw.fill_color = Color(color1)
    draw.color(0,0,'point')
    draw.fill_color = Color(color2)
    draw.color(0,0,'replace')
    draw.fill_color = BLANK
    draw.color(0,0,'point')
    return draw

REPLACERS = { 
    'tcop->ttin': [
        Replacer('#763228', '#675248'), # darkest
        Replacer('#bd3c2e', '#8f7d74'),
        Replacer('#e85643', '#baa195'),
        Replacer('#ff8d7d', '#cebcb5'), # lightest
        Replacer('#560d05', '#281f1a'), # bg
    ],
    'tcop->tste': [
        Replacer('#763228', '#450009'), # darkest
        Replacer('#bd3c2e', '#98323d'),
        Replacer('#e85643', '#b66d71'),
        Replacer('#ff8d7d', '#eb939a'), # lightest
        Replacer('#560d05', '#170608'), # bg
    ],
    'tcha->tgol': [
        Replacer('#35481e', '#610002'), # darkest
        Replacer('#4d6c27', '#be4205'),
        Replacer('#5fb052', '#f06e0b'),
        Replacer('#74d864', '#ffc948'), # lightest
        Replacer('#1a260c', '#3f1f10'), # bg
    ],
    'tcha->cgls': [
        Replacer('#35481e', '#192d36'), # darkest
        Replacer('#4d6c27', '#11484a'),
        Replacer('#5fb052', '#90a5c8'),
        Replacer('#74d864', '#d9ccee'), # lightest
        Replacer('#1a260c', '#0a0c0d'), # bg
    ],
    'tcop->tcha': [
        Replacer('#763228', '#35481e'), # darkest
        Replacer('#bd3c2e', '#4d6c27'),
        Replacer('#e85643', '#5fb052'),
        Replacer('#ff8d7d', '#74d864'), # lightest
        Replacer('#560d05', '#1a260c'), # bg
    ]
}

CONVERSIONS =  [ ('tcop', 'ttin'), ('tcop', 'tste'), ('tcha', 'tgol'), ('tcha', 'cgls') ]

for conversion in CONVERSIONS:
    filepairs = []
    cfrom = conversion[0]
    cto = conversion[1]
    for armor in ARMORS:
        for pic in PICS:
            filepairs.append(( 'terumet_'+pic+armor+'_'+cfrom+'.png', 'terumet_'+pic+armor+'_'+cto+'.png' ))
    
    replacers = REPLACERS[cfrom + '->' + cto]

    for filepair in filepairs:
        fromfile = filepair[0]
        tofile = filepair[1]
        print('processing '+fromfile+' to '+tofile)
        with Image(filename=fromfile) as img:

            with Drawing() as draw:
                for rep in replacers:
                    rep(img)
            img.save(filename=tofile)

