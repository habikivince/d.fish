# d.fish

🇫🇷 [Français](#français) · 🇬🇧 [English](#english)

---

## Français

`d` est une fonction pour le shell [fish](https://fishshell.com/) qui télécharge des vidéos YouTube avec [yt-dlp](https://github.com/yt-dlp/yt-dlp), en s'appuyant sur [bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider) pour les PO Tokens.

### Ce qu'elle fait

- Vérifie que le provider bgutil répond (`/ping`) avant de télécharger, et relance son conteneur Docker s'il est arrêté.
- **Abandonne** si le provider reste indisponible : sans PO Token, yt-dlp peut retomber en silence sur une basse qualité, et la vidéo serait alors inscrite dans l'archive.
- Tient une archive (`archive.txt`) pour ne jamais retélécharger une vidéo.
- Choisit la meilleure résolution, fusionne en MKV, intègre chapitres, miniature, métadonnées et sous-titres (piste désactivable, non incrustée dans l'image).
- Accepte une ou plusieurs URL, ou un fichier texte contenant une URL par ligne.
- Peut mettre yt-dlp à jour une fois par jour (optionnel).

### Prérequis

- fish ≥ 3.6
- yt-dlp, avec le plugin bgutil-ytdlp-pot-provider installé
- ffmpeg, curl
- Docker, avec le conteneur du provider :

```fish
docker run --name bgutil-provider -d --init --restart unless-stopped \
    -p 127.0.0.1:4416:4416 brainicism/bgutil-ytdlp-pot-provider
```

### Installation

Avec [fisher](https://github.com/jorgebucaran/fisher) :

```fish
fisher install habikivince/d.fish
```

Ou à la main : copier `functions/d.fish` dans `~/.config/fish/functions/`.

### Utilisation

```fish
d URL
d URL1 URL2 URL3
d liste_urls.txt
d --no-download-archive URL   # les options yt-dlp sont transmises telles quelles
```

### Réglages

Tous optionnels, à définir une seule fois avec `set -U NOM valeur`.

| Variable | Rôle | Défaut |
|---|---|---|
| `D_OUTDIR` | Dossier de destination | `<Vidéos>/youtube` |
| `D_REQUIRE_MOUNT` | Point de montage exigé avant d'écrire | aucun |
| `D_LANG` | Langue préférée (audio et sous-titres), ex. `fr` | aucune |
| `D_COOKIES_BROWSER` | Navigateur dont lire les cookies, ex. `firefox` | aucun |
| `D_UPDATE_CHANNEL` | Canal de mise à jour quotidienne de yt-dlp, ex. `master` | pas de mise à jour |
| `D_POT_URL` | URL du provider bgutil | `http://127.0.0.1:4416` |
| `D_POT_CONTAINER` | Nom du conteneur Docker | `bgutil-provider` |
| `D_NO_POT` | Si définie, ne vérifie pas le provider | non définie |

### Avertissements

- `D_UPDATE_CHANNEL` ne fonctionne qu'avec le binaire autonome de yt-dlp, pas avec une installation par gestionnaire de paquets ou pip.
- Utiliser les cookies de son compte avec yt-dlp peut exposer ce compte à des restrictions ; voir le wiki de yt-dlp.
- Respectez les conditions d'utilisation des sites et le droit d'auteur.
- Fonction personnelle, fournie sans garantie.

---

## English

`d` is a [fish](https://fishshell.com/) shell function that downloads YouTube videos with [yt-dlp](https://github.com/yt-dlp/yt-dlp), relying on [bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider) for PO Tokens. Messages printed by the function are in French.

### What it does

- Checks that the bgutil provider answers (`/ping`) before downloading, and restarts its Docker container if it is stopped.
- **Aborts** if the provider stays unreachable: without a PO Token, yt-dlp may silently fall back to low quality, and that video would then be recorded in the archive.
- Keeps a download archive (`archive.txt`) so a video is never downloaded twice.
- Picks the best resolution, merges to MKV, embeds chapters, thumbnail, metadata and subtitles (soft track, not burned in).
- Takes one or more URLs, or a text file with one URL per line.
- Can update yt-dlp once a day (optional).

### Requirements

- fish ≥ 3.6
- yt-dlp, with the bgutil-ytdlp-pot-provider plugin installed
- ffmpeg, curl
- Docker, with the provider container:

```fish
docker run --name bgutil-provider -d --init --restart unless-stopped \
    -p 127.0.0.1:4416:4416 brainicism/bgutil-ytdlp-pot-provider
```

### Install

With [fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install habikivince/d.fish
```

Or manually: copy `functions/d.fish` into `~/.config/fish/functions/`.

### Usage

```fish
d URL
d URL1 URL2 URL3
d url_list.txt
d --no-download-archive URL   # extra yt-dlp options are passed through
```

### Settings

All optional; set once with `set -U NAME value`.

| Variable | Purpose | Default |
|---|---|---|
| `D_OUTDIR` | Destination folder | `<Videos>/youtube` |
| `D_REQUIRE_MOUNT` | Mount point required before writing | none |
| `D_LANG` | Preferred language (audio and subtitles), e.g. `fr` | none |
| `D_COOKIES_BROWSER` | Browser to read cookies from, e.g. `firefox` | none |
| `D_UPDATE_CHANNEL` | Daily yt-dlp update channel, e.g. `master` | no update |
| `D_POT_URL` | bgutil provider URL | `http://127.0.0.1:4416` |
| `D_POT_CONTAINER` | Docker container name | `bgutil-provider` |
| `D_NO_POT` | If set, skips the provider check | unset |

### Caveats

- `D_UPDATE_CHANNEL` only works with the standalone yt-dlp binary, not with a package-manager or pip install.
- Using your account cookies with yt-dlp may expose that account to restrictions; see the yt-dlp wiki.
- Respect each site's terms of service and copyright law.
- Personal function, provided without warranty.

---

Licence / License: [Unlicense](UNLICENSE) (domaine public / public domain).
