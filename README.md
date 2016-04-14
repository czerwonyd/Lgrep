# English note
Sorry for creating only Polish documentation but the script was made as a project for one subject at Cracow University of Technology.

The program itself and comments in it are in English so it should be easy to understand the concept.

# Wstęp
Program lgrep jest narzędziem wspomagającym pracę administratorów systemów Linuksowych oraz BSD.

Z założenia program ma pomóc w przeszukiwaniu dużych ilości dzienników systemowych przez filtrowanie linii po słowach kluczowych. W praktyce jednak można go użyć do dowolnego katalogu i plików w nim zawartych, z których chcemy często wybierać pasujące do słów kluczowych linie.

# Sposób użycia
## Konfiguracja lgrepa
Po sklonowaniu repozytorium programu należy skonfigurować program ustawiając ścieżki w pliku `lgrep_config.cfg`.

Najlepiej skopiować przykładowy plik `lgrep_config.sample.cfg` do `lgrep_config.cfg`
Inicjacja środowiska

W celu zainicjowania środowiska plików konfiguracyjnych należy uruchomić program z parametrem -i.

Spowoduje to stworzenie kopii drzewa katalogów z katalogu `TO_FILTER_DIR` w katalogu przechowującym dostępne konfiguracje `AVAILABLE_CONF_DIR`.

## Budowa plików konfiguracyjnych
Podczas inicjacji każdy z plików konfiguracyjnych został uzupełniony bazową treścią tłumaczącą zasadę działania. Zasada działania jest następująca:
* linie rozpoczynające się od znaku „+” są dodane jako wymagane, połączone alternatywą logiczną
* linie rozpoczynające się od znaku „-” są dodane jako słowo odrzucające linię, połączone również alternatywą logiczną (czyli przy zaprzeczeniu jest to suma logiczna)
* wszystkie inne linie są ignorowane

Słowo kluczowe może być dowolnym wyrażeniem regularnym akceptowanym przez egrep ([man egrep](http://linux.die.net/man/1/egrep)).

## Włączenie konfiguracji
Następnie trzeba włączyć konfigurację. W tym celu należy podać komendę enable i nazwę pliku:

    % lgrep -e cups/error_log

Komenda ta przekopiuje plik z katalogu `AVAILABLE_CONF_DIR` do `CONF_DIR` i utworzy brakujące katalogi.
## Wyłączenie konfiguracji
Można również wyłączyć konfigurację. W tym celu należy podać komendę disable i nazwę pliku:

    % lgrep -d cups/error_log
Komenda ta usunie plik z katalogu `CONF_DIR` i usunie drzewo nadrzędnych katalogów, które są puste.
## Przykładowe konfiguracje
### Nginx
Po tym trzeba zgodnie ze swoimi wymaganiami przystosować odpowiednią konfigurację. Przykładem pliku konfiguracyjnego dla error-log NginXa może być:

    +[error]
    +[warn]
Który sprawi, że w przefiltrowanej wersji otrzymam tylko linie zawierające słowa kluczowe `[error]` oraz `[warn]`.
### Security log (FreeBSD)
Drugim przykładem pliku konfiguracyjnego może być konfiguracja dziennika systemowego `security` w systemie FreeBSD:

    +su: BAD SU
    -BAD SU admin
Która sprawi, że w przefiltrowanej wersji otrzymam wszystkie nieudane próby przelogowania nie licząc nieudanych prób użytkownika `admin`.
# Uruchomienie programu
Po przeprowadzeniu konfiguracji należy uruchomić program. Po tym w katalogu `FILTERED_DIR` będą znajdowały się przefiltrowane pliki.
Każdorazowe uruchomienie programu nadpisuje pliki stworzone wcześniej. Lgrep z założenia ma jedynie pomóc w przesiewaniu plików tekstowych, więc nie ma sensu zapamiętywanie starych wersji przefiltrowanych plików.
