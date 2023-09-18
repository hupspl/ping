#!/bin/bash

# Pobranie aktualnej daty
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Nazwa pliku z listą adresów IP i nazw hostów
IP_LIST_FILE="ip_list.txt"

# Tablica na adresy IP i nazwy hostów
declare -a IP_ADDRESSES
declare -a HOSTS

# Odczytanie adresów IP i nazw hostów z pliku
while IFS=':' read -r ip host; do
    IP_ADDRESSES+=("$ip")
    HOSTS+=("$host")
done < "$IP_LIST_FILE"

# Maksymalna liczba plików do zapisania
MAX_FILES=10

# Nazwa pliku HTML
BASE_HTML_FILE="ping_results"

# Nazwa pliku z listą hostów z sukcesem
SUCCESS_HOST_FILE="host.txt"

# Usunięcie pliku jeśli istnieje
rm -f "$SUCCESS_HOST_FILE"

# Dodanie FontAwesome do nagłówka HTML
FONT_AWESOME="<link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css'>"

# Funkcja do sprawdzania wyniku pingu
check_ping() {
    local ip="$1"
    if ping -c2 "$ip" &> /dev/null; then
        echo "<td class='text-success'><i class='fas fa-check'></i></td>"
    else
        echo "<td class='text-danger'><i class='fas fa-times'></i></td>"
    fi
}

# Sprawdzenie, ile razy skrypt został uruchomiony
if [ -f run_count.txt ]; then
    RUN_COUNT=$(cat run_count.txt)
else
    RUN_COUNT=0
fi

# Zaktualizowanie licznika
((RUN_COUNT++))
echo "${RUN_COUNT}" > run_count.txt

# Ustalamy numer pliku (cyklicznie od 1 do MAX_FILES)
FILE_NUM=$(( (RUN_COUNT - 1) % MAX_FILES + 1 ))

# Nazwa pliku HTML z numerem uruchomienia
HTML_FILE="${BASE_HTML_FILE}_${FILE_NUM}.html"

# Jeśli osiągnięto limit zapisów, usuń najstarszy plik
if ((RUN_COUNT > MAX_FILES)); then
    OLDEST_FILE_NUM=$(( (RUN_COUNT - MAX_FILES - 1) % MAX_FILES + 1 ))
    OLDEST_FILE="${BASE_HTML_FILE}_${OLDEST_FILE_NUM}.html"
    rm -f "${OLDEST_FILE}"
fi

# Rozpoczęcie tworzenia pliku HTML
if [ ! -f "${HTML_FILE}" ]; then
    cat > "${HTML_FILE}" <<EOF
<html>
<head>
    <title>Ping Results</title>
    <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css'>
    ${FONT_AWESOME} <!-- Dodanie FontAwesome -->
</head>
<body>
<h1 class='text-primary text-center'>Ping Report - ${CURRENT_DATE}</h1>
<table class='table table-bordered mx-auto' style='max-width: 800px; margin-top: 80px;'>
    <tr class='text text-center'>
        <th>Adres IP</th>
        <th>Nazwa Hosta</th>
        <th>Wynik Pingu</th>
    </tr>
EOF
fi

# Tablica na hosty z sukcesem
declare -a SUCCESS_HOSTS

# Iteracja po posortowanych adresach IP i nazwach hostów
for i in "${!IP_ADDRESSES[@]}"; do
    IP_TO_PING="${IP_ADDRESSES[$i]}"
    HOST_NAME="${HOSTS[$i]}"
    RESULT=$(check_ping "$IP_TO_PING")

    if [ "$RESULT" == "<td class='text-success'><i class='fas fa-check'></i></td>" ]; then
        SUCCESS_HOSTS+=("$IP_TO_PING")
    fi

    cat >> "${HTML_FILE}" <<EOF
    <tr class='text text-center'>
        <td>${IP_TO_PING}</td>
        <td>${HOST_NAME}</td>
        ${RESULT}
    </tr>
EOF
done

# Zakończenie pliku HTML
cat >> "${HTML_FILE}" <<EOF
</table>
</body>
</html>
EOF

# Zapis hostów z sukcesem do pliku
for host in "${SUCCESS_HOSTS[@]}"; do
    echo "$host" >> "$SUCCESS_HOST_FILE"
done

echo "Wyniki zostały zapisane w ${HTML_FILE}"
