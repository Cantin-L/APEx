#!/bin/bash
#author : R. Batelier & C.Liottard
clear

# Variables
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
read -p "IP ou URL à attaquer : " ip
echo ""
read -p "Est-ce bien la cible $ip ? (y/n) - " rep

if [ "$rep" = "y" ]; then
  echo ""
  sleep 1
else
  echo "Arrêt."
  exit
fi

echo "Lancement d'APEX Scan"
echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter nmap et rediriger la sortie vers un fichier temporaire
echo "			    NMAP"
nmap -sS -sV -T4 -p 80,443 "$ip" > rapport_nmap_temp.txt

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter nmap et rediriger la sortie vers un fichier temporaire
echo "			   VULNERS"
nmap -sV --script vulners "$ip" > rapport_vulners_temp.txt

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter nmap et rediriger la sortie vers un fichier temporaire
echo "			    FUFF"
#ffuf -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -recursion -u http://"$ip"/FUZZ

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter WPSCAN et rediriger la sortie vers un fichier temporaire
echo "			   WPSCAN"
wpscan --url "$ip" -o rapport_wpscan_temp.txt
grep "Scan Aborted" rapport_wpscan_temp.txt > rapport_wpscan_ScanAborted.txt
ttest="Scan Aborted: The remote website is up, but does not seem to be running WordPress."
if [ "$ttest" = "Scan Aborted: The remote website is up, but does not seem to be running WordPress." ]; then
  wpscan="Le site n'est pas un WordPress."
else
  wpscan="Scan: "
fi

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter nmap et rediriger la sortie vers un fichier temporaire
echo "			  RAPIDSCAN"
#python3 rapidscan.py --skip nmap "$ip" > rapport_rapidscan_temp.txt

echo ""
echo "+-----------------------------------------------------------+"
echo ""

# Exécuter nmap et rediriger la sortie vers un fichier temporaire
echo "			  NSLOOKUP"
nslookup "$ip" > rapport_nslookup_temp.txt

echo ""
echo "+-----------------------------------------------------------+"
echo ""
echo "Fin d'APEX Scan"

date=$(date '+%d/%m/%Y')

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
     <p>Date: $date - Version: 1.0</p>
  </center>
  
  <h2>Information de la machine cible:</h2>
  <p>IP Address: $(grep -oE "([0-9]{1,3}[.]){3}[0-9]{1,3}" rapport_nmap_temp.txt)</p>
  <p>$(grep "MAC Address:" rapport_nmap_temp.txt)</p>
  <p>DNS: $(grep "name =" rapport_nslookup_temp.txt | awk '{print $NF}')</p>
  
  <h2>Nmap</h2>
  <h3>Le temps du scan:</h3>
  <p>Durée du Nmap: $(tail -n1 rapport_nmap_temp.txt | grep -oE "([0-9]{1,2}[.])[0-9]{1,2}") secondes</p>
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
    $(grep -E "^[0-9]+/tcp\s+open\s+.+" rapport_nmap_temp.txt | awk '/^[0-9]/ {print "<tr><td>" $1 "</td><td>" $3 "</td><td>" $4; for(i=5; i<=NF; i++) printf(" %s", $i); printf("</td></tr>\n") }')
  </tbody>
  </table>
  
  <h3>FUFF:</h3>
  
  <h3>Exploits:</h3>
  <p>$(awk '/*EXPLOIT*/ {
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
  </p>
  
  <h2>Wpscan</h2>
  <p>$wpscan</p>
  
  <h2>Rapidscan</h2>
  <p></p>
  
</body>
</html>
EOF

# Convertir le fichier HTML en PDF avec WeasyPrint
weasyprint rapport_html_temp.html rapport_apex.pdf

# Supprimer les fichiers temporaires
rm rapport_nmap_temp.txt rapport_wpscan_temp.txt rapport_wpscan_ScanAborted.txt rapport_html_temp.html rapport_nslookup_temp.txt #rapport_rapidscan_temp.txt
