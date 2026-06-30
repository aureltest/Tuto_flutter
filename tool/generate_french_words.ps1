# Génère lib/french_words.dart à partir de sources publiques.
#
#   legalWords   = les mots français de 5 lettres les plus fréquents (réponses),
#                  hors liste d'exclusion ci-dessous.
#   legalGuesses = tous les autres mots de 5 lettres du dictionnaire
#                  (acceptés en saisie mais jamais choisis comme réponse).
#
# Sources :
#   Dictionnaire : https://github.com/chrplr/openlexicon (liste Gutenberg)
#   Fréquences   : https://github.com/hermitdave/FrequencyWords (fr_50k)
#
# Lancer depuis la racine du projet :  pwsh tool/generate_french_words.ps1

$ErrorActionPreference = 'Stop'

# Nombre de mots-réponses à conserver (les N plus fréquents, exclusions retirées).
$limit = 1200

# --- Liste d'exclusion -------------------------------------------------------
# Mots-outils et conjugaisons d'auxiliaires : valides comme guess, mais de
# mauvaises réponses. Ajoute/retire librement (en minuscules, sans accents).
$exclude = @(
  # déterminants / pronoms / conjonctions / prépositions / adverbes grammaticaux
  'comme', 'cette', 'votre', 'notre', 'leurs', 'elles', 'celle', 'celui',
  'quand', 'alors', 'aussi', 'parce', 'avant', 'apres', 'ainsi', 'assez',
  'enfin', 'certes', 'voire', 'voila', 'voici', 'selon', 'entre', 'parmi',
  'aucun', 'ouais', 'toute', 'quels', 'quelle',
  # être / avoir / aller (formes conjuguées)
  'etait', 'etais', 'etant', 'serai', 'seras', 'serez', 'soyez',
  'avait', 'avais', 'ayant', 'ayons', 'aurai', 'auras', 'aurez',
  'allez', 'irais', 'irait', 'irons', 'iriez'
)
# ----------------------------------------------------------------------------

$wc = New-Object System.Net.WebClient
$gutUrl  = 'https://raw.githubusercontent.com/chrplr/openlexicon/master/datasets-info/Liste-de-mots-francais-Gutenberg/liste.de.mots.francais.frgut.txt'
$freqUrl = 'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/fr/fr_50k.txt'
$gutText  = [System.Text.Encoding]::UTF8.GetString($wc.DownloadData($gutUrl))
$freqText = [System.Text.Encoding]::UTF8.GetString($wc.DownloadData($freqUrl))

$oe = [string][char]0x153
$ae = [string][char]0xE6
function Convert-Norm([string]$w) {
  if ([string]::IsNullOrWhiteSpace($w)) { return '' }
  $w = $w.Trim().ToLowerInvariant().Replace($script:oe, 'oe').Replace($script:ae, 'ae')
  $d = $w.Normalize([System.Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$sb.Append($ch)
    }
  }
  return $sb.ToString()
}

# Univers des mots valides : dico Gutenberg filtré à 5 lettres a-z, normalisé.
$gut = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($line in ($gutText -split "`r?`n")) {
  $nw = Convert-Norm $line
  if ($nw -match '^[a-z]{5}$') { [void]$gut.Add($nw) }
}

$excludeSet = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in $exclude) { [void]$excludeSet.Add($w) }

# Réponses : top fréquence ∩ dico, hors exclusions.
$answers = New-Object 'System.Collections.Generic.HashSet[string]'
$skipped = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in ($freqText -split "`r?`n")) {
  if ($answers.Count -ge $limit) { break }
  $nw = Convert-Norm (($line -split '\s+')[0])
  if ($nw -match '^[a-z]{5}$' -and $gut.Contains($nw)) {
    if ($excludeSet.Contains($nw)) { $skipped.Add($nw) }
    else { [void]$answers.Add($nw) }
  }
}

# Guesses : tout le reste du dico.
$rest = New-Object 'System.Collections.Generic.List[string]'
foreach ($w in $gut) { if (-not $answers.Contains($w)) { $rest.Add($w) } }

$legalWords   = $answers | Sort-Object
$legalGuesses = $rest | Sort-Object

Write-Host "legalWords : $($answers.Count)   legalGuesses : $($rest.Count)   total : $($gut.Count)"
Write-Host "Exclus du top fréquence ($($skipped.Count)) : $($skipped -join ', ')"

$wordsItems = ($legalWords   | ForEach-Object { "  '$_'," }) -join "`n"
$guessItems = ($legalGuesses | ForEach-Object { "  '$_'," }) -join "`n"
$dart = @"
// GENERATED FILE - do not edit by hand. Run tool/generate_french_words.ps1.
// Sources:
//   Dictionnaire : https://github.com/chrplr/openlexicon (liste Gutenberg)
//   Frequences   : https://github.com/hermitdave/FrequencyWords (fr_50k)
// Five-letter French words, normalized (lowercased, accent-free).

/// The $($answers.Count) most common five-letter French words, used as hidden words.
const List<String> legalWords = [
$wordsItems
];

/// Additional valid five-letter words accepted as guesses but never chosen
/// as the hidden word.
const List<String> legalGuesses = [
$guessItems
];
"@

$out = Join-Path (Get-Location) 'lib/french_words.dart'
[System.IO.File]::WriteAllText($out, $dart, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Ecrit : $out ($([math]::Round((Get-Item $out).Length/1KB)) Ko)"
