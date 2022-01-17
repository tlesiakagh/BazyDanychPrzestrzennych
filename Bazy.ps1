##---------------------------CHANGELOG-----------------------------------
# Data utworzenia: 01.01.2022
# 
# Opis skryptu:
#
# Zadaniem skryptu jest automatyczne wyszukanie najlepszych klientów spośród listy.
# Lista klientów jest plikem csv umieszczonym na serwerze.
# Po pobraniu jest ona porównywana z lokalnie zapisaną starą listą i wybierani są z niej tylko nowi klienci.
# W celu wyszukania najlepszych klientów użyta została baza danych Postgresql z rozszerzeniem PostGIS.
# Dodatkowo skrypt informuje o wynikach swojej pracy wysłyjąc maile.
# Wynikiem jego działania jest lista klientów best_customers400096 zapisana w pliku csv i umieszczona w archiwum o tej samej nazwie.
#
# Porady do uruchomienia:
#
# Skrypt podczas uruchomienia utworzy folder OUTPUT, gdzie będą znajdowały się wszystkie pliku będące wynikiem jego działania.
# Folder OUTPUT zostanie utworzony w tym samym folderze co znajduje się skrypt.
# W tym samymy folderze należy umieścić też plik Customers_old.csv
# W trakcie uruchomienia wysyłane zostaną 2 maile z informacjami o przetwarzaniu listy klientów.
# Logi skryptu znajdują się w folderze OUTPUT jako plik o nazwie bazy.log.txt
# 
##-----------------------------------------------------------------------

# Funckcja logująca
function Write-Log {
    param (
        $action
    )

    $tmp = Get-Date -Format "MM/dd/yyyy HH:mm"
     
    if($?){
        $tmp += " - $action - SUCCESFUL" 
    }else{
        $tmp += " - $action - FAILED" 
    }

    $tmp >> "$folderPath\$logFileName"
}

# Sparametryzowane wartości
$url = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip"
$folderPath = $PSScriptRoot + "\OUTPUT"
$downloadedFileName = $url.split('/')[-1].split('.')[0]
$filePath = $folderPath + "\" + $downloadedFileName
$zipPassword = "agh"
$timestmap = Get-Date -Format "MMddyyyy"
$myIndex = 400096
$logFileName = "bazy.log"
$username = "postgres"
$password = "postgres"
$port = 5432
$server = "127.0.0.1"
$database = "skrypt"
$mail = "zdunleszek26@gmail.com"
$smtpServer = "smtp.gmail.com"
$conn = New-Object System.Data.Odbc.OdbcConnection
$connStr = "Driver={PostgreSQL Unicode(x64)};Server=$server;Port=$port;Database=$database;Uid=$username;Pwd=$password;"
$conn.ConnectionString = $connStr

Remove-Item $folderPath -Recurse -ErrorAction Ignore

# Pobranie pliku zip i zapis do folderu, w którym odpalany jest skrypt
New-Item $folderPath -ItemType Directory
New-Item "$folderPath\$logFileName" -ItemType File
$client = New-Object System.Net.WebClient
$client.DownloadFile($url,$filePath + ".zip")
# Logowanie
Write-Log -action "DOWNLOAD"

# Rozpakowanie pobranego archiwum do tego samego folderu co został pobrany
Expand-7Zip -ArchiveFileName ($filePath + ".zip") -TargetPath $folderPath -Password $zipPassword
# Logowanie
Write-Log -action "UNZIPING"
Remove-Item ($folderPath + "\*.zip")

# Walidacja pliku Customers_Nov2021.csv na podstawie pola email 
$importedCsv = Import-Csv -Path ($filePath + ".csv")
$file = Get-Item ($filePath + ".csv")
$CSVLastMOdificationDate = $file.LastWriteTime
$oldCsv = Import-Csv -Path ($PSScriptRoot + "\Customers_old.csv")

# Pobranie liczby wierszy w pobranym pliku
$downloadedRowsAmount = $importedCsv.Count

#Plik zawierający tylko te rekordy nie występujące w Customers_old - o nazwie Customers_Nov2021
Compare-Object -ReferenceObject $oldCsv -DifferenceObject $importedCsv -Property email -PassThru | Where-Object SideIndicator -eq "=>" | 
Select-Object -Property first_name, last_name, email, lat, long | export-csv ($filePath + ".csv") -NoTypeInformation -Encoding UTF8
# logowanie
Write-Log -action "CSV PROCESSING"

#Plik zawierający powtarzające się rekordy - o nazwie Customers_Nov2021_bad_${TIMESTMAP}
Compare-Object -ReferenceObject $oldCsv -DifferenceObject $importedCsv -Property email -PassThru -IncludeEqual | Where-Object SideIndicator -eq "==" | 
Select-Object -Property first_name, last_name, email, lat, long | export-csv ($folderPath + "\" + $downloadedFileName + "_bad_" + $timestmap + ".csv") -NoTypeInformation -Encoding UTF8

#Połączenie z bazą danych i załadowanie do niej danych z pliku CSV
$conn.Open()
$sqlCommand = "CREATE TABLE 
               IF NOT EXISTS 
               Customers_$myIndex(
               ID serial,
               first_name varchar(100) NOT NULL,
               last_name varchar(100) NOT NULL,
               email varchar(100) NOT NULL,
               lat numeric(9,6) NOT NULL,
               long numeric(9,6) NOT NULL
               );
               TRUNCATE TABLE Customers_$myIndex;
               COPY Customers_$myIndex(first_name, last_name, email, lat, long)
               FROM $filePath.csv
               DELIMITER ','
               CSV HEADER;"                             
$cmd = New-object System.Data.Odbc.OdbcCommand($sqlCommand,$conn)
# logowanie
Write-Log -action "DATABASE LOAD"
$conn.Close()

#Przeniesienie do PROCESSED zweryfikowanego pliku
New-Item -Path ($folderPath + "\PROCESSED") -ItemType Directory
Move-Item -Path ($filePath + ".csv") -Destination ($folderPath + "\PROCESSED\" + $timestmap + "_" + $downloadedFileName + ".csv")
$processedFilePath = $folderPath + "\PROCESSED\" + $timestmap + "_" + $downloadedFileName + ".csv"

#Zebranie informacji potrzebnych w raporcie wysyłanym mailem
$processedCsv = Import-Csv -Path $processedFilePath
$badCsv = Import-Csv -Path ($filePath + "_bad_" + $timestmap + ".csv")
$processedRowsAmount = $processedCsv.Count
$badRowsAmount = $badCsv.Count

$conn.Open()
$sqlCommand = "SELECT * FROM public.customers_$myIndex"
$cmd = New-object System.Data.Odbc.OdbcCommand($sqlCommand,$conn)
$dataset = New-Object System.Data.DataSet
(New-Object System.Data.Odbc.OdbcDataAdapter($cmd)).Fill($dataSet) | out-null
$conn.Close()
$copiedRowsAmount = $dataset.Tables[0].rows.Count

#Wysyłanie emaila z podsumowanie
$subject = "CUSTOMERS LOAD - $timestmap"
$body = "liczba wierszy w pliku pobranym z internetu: $downloadedRowsAmount
liczba poprawnych wierszy (po czyszczeniu): $processedRowsAmount
liczba duplikatów w pliku wejściowym: $badRowsAmount
ilość danych załadowanych do tabeli customers_{NUMER_INDEKSU}: $copiedRowsAmount"
$smtpClient = New-Object Net.Mail.SmtpClient($smtpServer, 587)
$smtpClient.EnableSsl = $true
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($mail, "cjqarucfaeqojmig")
$smtpClient.Send($mail, $mail, $subject, ($body | Out-String))

#Wybranie najlepszych klientów
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "DROP TABLE public.BEST_CUSTOMERS_$myIndex;
                    SELECT first_name, last_name
                    INTO public.BEST_CUSTOMERS_$myIndex
                    FROM public.customers_$myIndex
                    WHERE ST_DWithin(St_Point(lat, long)::geography, St_Point(41.39988501005976, -75.67329768604034)::geography, 50000);"
$cmd.ExecuteReader();
# logowanie
Write-Log -action "DATABASE PROCESSING"
$conn.Close()

#Eksport tabeli best_customers do pliku .csv, a następnie spakowanie go do archiwum
$conn.Open()
$sqlCommand = "SELECT * FROM public.BEST_CUSTOMERS_$myIndex"
$cmd = New-object System.Data.Odbc.OdbcCommand($sqlCommand,$conn)
$dataset = New-Object System.Data.DataSet
(New-Object System.Data.Odbc.OdbcDataAdapter($cmd)).Fill($dataSet) | out-null
$conn.Close()

$bestCustomersPath = $folderPath + "\best_customers" + $myIndex 
$dataset.Tables[0] | Export-Csv -Path ($bestCustomersPath + ".csv") -NoTypeInformation
Compress-Archive -Path ($bestCustomersPath + ".csv") -DestinationPath ($bestCustomersPath + ".zip")
# logowanie
Write-Log -action "ZIPPING"
Remove-Item ($bestCustomersPath + ".csv")

$processedRowsAmount = $dataset.Tables[0].rows.Count

$subject = "LIST OF BEST CUSTOMERS - $timestmap"
$body = "data ostatniej modyfikacji: $CSVLastMOdificationDate
ilość wierszy w pliku best_customers.csv: $processedRowsAmount"
$smtpClient = New-Object Net.Mail.SmtpClient($smtpServer, 587)
$smtpClient.EnableSsl = $true
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($mail, "cjqarucfaeqojmig")
$smtpClient.Send($mail, $mail, $subject, ($body | Out-String))