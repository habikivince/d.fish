function d --description "Télécharge des vidéos YouTube via yt-dlp (+ bgutil-provider)"
    # Réglages (tous optionnels) — à définir une fois avec `set -U NOM valeur` :
    #   D_OUTDIR           dossier de destination        (défaut : <Vidéos>/youtube)
    #   D_REQUIRE_MOUNT    point de montage exigé avant d'écrire (défaut : aucun)
    #   D_LANG             langue préférée, audio + sous-titres, ex. fr (défaut : aucune)
    #   D_COOKIES_BROWSER  navigateur dont lire les cookies, ex. firefox (défaut : aucun)
    #   D_UPDATE_CHANNEL   canal de mise à jour quotidienne, ex. master (défaut : aucune màj)
    #   D_POT_URL          URL du provider bgutil        (défaut : http://127.0.0.1:4416)
    #   D_POT_CONTAINER    nom du conteneur Docker       (défaut : bgutil-provider)
    #   D_NO_POT           si définie, ne vérifie pas le provider (téléchargement
    #                      possiblement dégradé, à vos risques)

    # 1. Arguments : validés avant tout effet de bord (réseau, docker).
    if test (count $argv) -eq 0; or contains -- $argv[1] -h --help
        echo "Usage : d URL...   ou   d fichier_urls.txt" >&2
        echo "        Les options yt-dlp supplémentaires sont transmises telles quelles." >&2
        return 1
    end

    for cmd in yt-dlp curl
        if not command -q $cmd
            echo "✗ Commande introuvable : $cmd" >&2
            return 127
        end
    end

    # 2. Réglages et valeurs par défaut.
    set -l outdir $D_OUTDIR
    if test -z "$outdir"
        set -l videos ~/Videos
        command -q xdg-user-dir; and set videos (xdg-user-dir VIDEOS)
        set outdir $videos/youtube
    end
    set -l archive $outdir/archive.txt

    set -l pot_url http://127.0.0.1:4416
    set -q D_POT_URL[1]; and set pot_url (string trim -r -c / -- $D_POT_URL)
    set -l pot_container bgutil-provider
    set -q D_POT_CONTAINER[1]; and set pot_container $D_POT_CONTAINER

    set -l cache ~/.cache
    set -q XDG_CACHE_HOME[1]; and set cache $XDG_CACHE_HOME

    # 3. Mise à jour quotidienne de yt-dlp (seulement si D_UPDATE_CHANNEL est défini ;
    #    ne fonctionne qu'avec le binaire autonome, pas avec pacman/pip).
    #    Le tampon n'est mis à jour qu'en cas de succès : un échec est retenté
    #    au prochain appel au lieu d'être oublié pendant 24 h.
    if set -q D_UPDATE_CHANNEL[1]
        set -l stamp $cache/d-yt-dlp-update.stamp
        set -l age 999999
        test -f $stamp; and set age (path mtime -R $stamp)
        if test $age -gt 86400
            mkdir -p $cache
            if yt-dlp --update-to $D_UPDATE_CHANNEL >/dev/null 2>&1
                touch $stamp
            else
                echo "⚠ Mise à jour de yt-dlp ($D_UPDATE_CHANNEL) échouée — nouvel essai au prochain appel." >&2
            end
        end
    end

    # 4. bgutil-provider fournit les PO Tokens ; sans lui yt-dlp dégrade
    #    silencieusement vers des formats bas de gamme. On teste le service
    #    (/ping), pas seulement l'existence du conteneur. En cas d'échec on
    #    ABANDONNE : une vidéo dégradée serait inscrite dans l'archive et ne
    #    serait plus jamais retéléchargée en bonne qualité.
    if not set -q D_NO_POT
        if not curl --noproxy '*' -fsS -m 2 $pot_url/ping >/dev/null 2>&1
            echo "⚠ bgutil-provider injoignable, tentative de (re)démarrage..." >&2
            if not command -q docker
                echo "✗ docker introuvable — impossible de démarrer le provider." >&2
                return 1
            end
            if not docker container inspect $pot_container >/dev/null 2>&1
                echo "✗ Conteneur « $pot_container » inexistant (ou docker inaccessible). Création :" >&2
                echo "    docker run --name $pot_container -d --init --restart unless-stopped \\" >&2
                echo "        -p 127.0.0.1:4416:4416 brainicism/bgutil-ytdlp-pot-provider" >&2
                return 1
            end
            docker start $pot_container >/dev/null 2>&1
            set -l up 0
            for i in (seq 15)
                if curl --noproxy '*' -fsS -m 2 $pot_url/ping >/dev/null 2>&1
                    set up 1
                    break
                end
                sleep 1
            end
            if test $up -eq 0
                echo "✗ bgutil-provider toujours indisponible — abandon." >&2
                echo "  (Pour télécharger malgré tout : set -x D_NO_POT 1)" >&2
                return 1
            end
        end
    end

    # 5. Destination. Si D_REQUIRE_MOUNT est défini, on refuse d'écrire tant que
    #    le disque n'est pas monté (sinon mkdir remplirait le disque système).
    if set -q D_REQUIRE_MOUNT[1]; and not mountpoint -q $D_REQUIRE_MOUNT
        echo "✗ Disque non monté : $D_REQUIRE_MOUNT" >&2
        return 1
    end
    mkdir -p $outdir; or return 1

    # 6. Entrée : un fichier de liste (-a ignore lignes vides et commentaires)
    #    ou une ou plusieurs URL. Un seul appel yt-dlp ; les erreurs sur une
    #    vidéo n'interrompent pas les suivantes.
    set -l src $argv
    if test (count $argv) -eq 1; and test -f $argv[1]
        set src -a $argv[1]
    end

    # 7. Options. -S : l'ordre par défaut de vcodec est déjà av01 > vp9.2 > vp9 > h265 > h264.
    #    L'identifiant [id] dans le nom évite les collisions entre vidéos de même titre.
    set -l fmt 'bv*+ba/best'
    set -l opts \
        -S 'res,fps,vcodec' \
        --merge-output-format mkv \
        --embed-chapters --embed-thumbnail \
        --embed-metadata --no-mtime \
        --retries 10 --fragment-retries 10 \
        --sleep-requests 2 \
        --download-archive $archive \
        -P $outdir \
        -o '%(title)s [%(id)s].%(ext)s'

    if set -q D_LANG[1]
        set fmt "bv*+ba[language^=$D_LANG]/$fmt"
        set -a opts --write-subs --sub-langs "$D_LANG.*"
    end
    if set -q D_COOKIES_BROWSER[1]
        set -a opts --cookies-from-browser $D_COOKIES_BROWSER
    end
    # Le plugin bgutil vise 127.0.0.1:4416 par défaut ; on ne lui passe l'URL
    # que si elle a été changée.
    if set -q D_POT_URL[1]
        set -a opts --extractor-args "youtubepot-bgutilhttp:base_url=$pot_url"
    end

    yt-dlp -f $fmt $opts $src
end
