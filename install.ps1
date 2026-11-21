# Tompachilo skill installer for Windows PowerShell 5.1+ and PowerShell 7.
#
#   irm https://raw.githubusercontent.com/urviljoshi/skills/main/install.ps1 | iex
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/urviljoshi/skills/main/install.ps1))) -To claude,codex -Skills all -Yes
#   .\install.ps1            (from a clone: installs from the local files)
#
# Skills and custom agents are discovered from skills/*/SKILL.md and agents/*.md,
# so new ones appear in the menu without changes to this script.
# This file is plain ASCII on purpose; special characters are built at run time.

param(
    [string[]]$To,          # claude, codex, copilot, all
    [string[]]$Skills,      # skill names, all
    [string[]]$Agents,      # custom agent names, all, none
    [switch]$Project,       # install into the current directory
    [switch]$Global,        # install for the user (default)
    [switch]$List,
    [switch]$Yes,
    [string]$Ref = $(if ($env:SKILLS_REF) { $env:SKILLS_REF } else { 'main' }),
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$Repo = if ($env:SKILLS_REPO) { $env:SKILLS_REPO } else { 'urviljoshi/skills' }
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$CHECK = [string][char]0x221A   # check mark that legacy console fonts have
$ARROW = [string][char]0x25BA
$ON    = [string][char]0x25A0
$OFF   = [string][char]0x25A1
$STAR  = [string][char]0x2666

if ($Help) {
    @'
Usage: install.ps1 [options]

With no options the installer asks everything in interactive menus.

  -To LIST       Coding agents: claude, codex, copilot, or all (comma separated)
  -Skills LIST   Skill names, or all
  -Agents LIST   Custom agents (Claude Code and Copilot only), all, or none
  -Global        Install for your user, in every project (default)
  -Project       Install into the current directory only
  -List          Show the available skills and agents, then exit
  -Ref REF       Git branch or tag to install from (default: main)
  -Yes           Do not ask; use defaults for anything not given
'@ | Write-Host
    return
}

function Split-List($values) {
    if (-not $values) { return @() }
    @($values | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
}
function Show-Tilde([string]$path) {
    if ($path.StartsWith($HOME)) { '~' + $path.Substring($HOME.Length) } else { $path }
}
function Stop-Install([string]$msg) { throw $msg }

function Show-Banner {
    # '#' = full block, the others are box-drawing characters.
    $map = @{ '#' = 0x2588; '[' = 0x2554; ']' = 0x2557; '{' = 0x255A; '}' = 0x255D; '=' = 0x2550; '|' = 0x2551 }
    $art = @(
        '   ########] ######] ###]   ###]######]  #####]  ######]##]  ##]##]##]      ######]',
        '   {==##[==}##[===##]####] ####|##[==##]##[==##]##[====}##|  ##|##|##|     ##[===##]',
        '      ##|   ##|   ##|##[####[##|######[}#######|##|     #######|##|##|     ##|   ##|',
        '      ##|   ##|   ##|##|{##[}##|##[===} ##[==##|##|     ##[==##|##|##|     ##|   ##|',
        '      ##|   {######[}##| {=} ##|##|     ##|  ##|{######]##|  ##|##|#######]{######[}',
        '      {=}    {=====} {=}     {=}{=}     {=}  {=} {=====}{=}  {=}{=}{======} {=====}'
    )
    $colors = 'Cyan', 'Cyan', 'Blue', 'Blue', 'Magenta', 'Magenta'
    Write-Host ''
    for ($i = 0; $i -lt $art.Count; $i++) {
        $line = -join ($art[$i].ToCharArray() | ForEach-Object {
            $k = [string]$_; if ($map.ContainsKey($k)) { [char]$map[$k] } else { $_ } })
        Write-Host $line -ForegroundColor $colors[$i]
    }
    Write-Host "   $STAR skill installer $STAR  " -ForegroundColor Magenta -NoNewline
    Write-Host 'skills for Claude Code, Codex & Copilot' -ForegroundColor DarkGray
    Write-Host ''
}

$Interactive = (-not $Yes) -and (-not $List) -and (-not [Console]::IsInputRedirected)

# ------------------------------------------------------------------ source --
$Src = $null
$Tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'skills'))) { $Src = $PSScriptRoot }

if (-not $List) { Show-Banner }

try {
if (-not $Src) {
    $Tmp = Join-Path ([IO.Path]::GetTempPath()) ("skills-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    $url = "https://github.com/$Repo/archive/$Ref.zip"
    Write-Host "  v fetching $Repo ($Ref) " -NoNewline -ForegroundColor Cyan
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        $zip = Join-Path $Tmp 'src.zip'
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $Tmp -Force
        $Src = (Get-ChildItem $Tmp -Directory | Select-Object -First 1).FullName
    } catch { Write-Host ''; Stop-Install "could not download $url" }
    Write-Host $CHECK -ForegroundColor Green
    Write-Host ''
}

# --------------------------------------------------------------- discovery --
function Get-Frontmatter([string]$file, [string]$key) {
    $lines = Get-Content -LiteralPath $file -Encoding UTF8
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return '' }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }
        if ($lines[$i] -match "^$key\s*:\s*(.*)$") { return $Matches[1].Trim().Trim('"', "'") }
    }
    ''
}

$SkillList = @(Get-ChildItem (Join-Path $Src 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    ForEach-Object { [pscustomobject]@{ Name = $_.Name; Desc = Get-Frontmatter (Join-Path $_.FullName 'SKILL.md') 'description' } })
if ($SkillList.Count -eq 0) { Stop-Install "no skills found in $Src\skills" }

$AgentList = @()
if (Test-Path (Join-Path $Src 'agents')) {
    $AgentList = @(Get-ChildItem (Join-Path $Src 'agents') -Filter *.md -File |
        ForEach-Object { [pscustomobject]@{ Name = $_.BaseName; Desc = Get-Frontmatter $_.FullName 'description'; Path = $_.FullName } })
}

function Limit-Text([string]$s, [int]$n) { if ($s.Length -le $n) { $s } else { $s.Substring(0, $n - 1) + '~' } }

if ($List) {
    Write-Host 'Skills:'
    $SkillList | ForEach-Object { Write-Host ('  {0,-20} {1}' -f $_.Name, (Limit-Text $_.Desc 90)) }
    Write-Host 'Custom agents (Claude Code, Copilot):'
    $AgentList | ForEach-Object { Write-Host ('  {0,-20} {1}' -f $_.Name, (Limit-Text $_.Desc 90)) }
    return
}

# ----------------------------------------------------------------- targets --
$Targets = @(
    [pscustomobject]@{ Id = 'claude';  Name = 'Claude Code';    Cmd = 'claude';  Dirs = @('.claude') }
    [pscustomobject]@{ Id = 'codex';   Name = 'Codex';          Cmd = 'codex';   Dirs = @('.codex', '.agents') }
    [pscustomobject]@{ Id = 'copilot'; Name = 'GitHub Copilot'; Cmd = 'copilot'; Dirs = @('.copilot') }
)
function Test-Detected($t) {
    if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) { return $true }
    foreach ($d in $t.Dirs) { if (Test-Path (Join-Path $HOME $d)) { return $true } }
    $false
}
function Get-SkillsDir([string]$id, [string]$scope) {
    $base = if ($scope -eq 'global') { $HOME } else { (Get-Location).Path }
    switch ("$id`:$scope") {
        'claude:global'   { Join-Path $base '.claude\skills' }
        'claude:project'  { Join-Path $base '.claude\skills' }
        'codex:global'    { Join-Path $base '.agents\skills' }
        'codex:project'   { Join-Path $base '.agents\skills' }
        'copilot:global'  { Join-Path $base '.copilot\skills' }
        'copilot:project' { Join-Path $base '.github\skills' }
    }
}
function Get-AgentsDir([string]$id, [string]$scope) {
    $base = if ($scope -eq 'global') { $HOME } else { (Get-Location).Path }
    switch ("$id`:$scope") {
        'claude:global'   { Join-Path $base '.claude\agents' }
        'claude:project'  { Join-Path $base '.claude\agents' }
        'copilot:global'  { Join-Path $base '.copilot\agents' }
        'copilot:project' { Join-Path $base '.github\agents' }
        default           { $null }
    }
}

# -------------------------------------------------------------------- menu --
# Show-Menu returns a bool[] of selections.
function Show-Menu([string]$title, [string[]]$labels, [string[]]$descs, [bool[]]$sel, [switch]$Single, [int]$Min = 0) {
    $n = $labels.Count
    $sel = [bool[]]$sel.Clone()
    $cur = 0
    if ($Single) { for ($i = 0; $i -lt $n; $i++) { if ($sel[$i]) { $cur = $i } } }
    $w = ($labels | Measure-Object -Property Length -Maximum).Maximum
    $cols = [Math]::Min([Console]::WindowWidth - 1, 110)
    $hint = if ($Single) { 'up/down move, enter select' } else { 'up/down move, space toggle, a all, enter confirm' }
    $height = $n + 2

    # Reserve space so that drawing near the bottom does not scroll the start away.
    Write-Host ("`n" * ($height - 1))
    $top = [Console]::CursorTop - $height
    if ($top -lt 0) { $top = 0 }
    $msg = ''
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $top)
            Write-Host '  ? ' -ForegroundColor Magenta -NoNewline
            Write-Host $title -NoNewline
            Write-Host ("  $hint").PadRight([Math]::Max(0, $cols - $title.Length - 4)) -ForegroundColor DarkGray
            for ($i = 0; $i -lt $n; $i++) {
                $isCur = ($i -eq $cur)
                $pointer = if ($isCur) { $ARROW } else { ' ' }
                $box = if ($Single) { if ($isCur) { $ON } else { $OFF } } elseif ($sel[$i]) { $ON } else { $OFF }
                $boxColor = if ($Single) { if ($isCur) { 'Cyan' } else { 'DarkGray' } } elseif ($sel[$i]) { 'Green' } else { 'DarkGray' }
                Write-Host "  $pointer " -ForegroundColor Cyan -NoNewline
                Write-Host $box -ForegroundColor $boxColor -NoNewline
                Write-Host (' ' + $labels[$i].PadRight($w) + '  ') -ForegroundColor $(if ($isCur) { 'Cyan' } else { 'Gray' }) -NoNewline
                $room = [Math]::Max(10, $cols - $w - 8)
                Write-Host (Limit-Text $descs[$i] $room).PadRight($room) -ForegroundColor DarkGray
            }
            Write-Host ('  ' + $msg).PadRight($cols) -ForegroundColor Yellow

            $key = [Console]::ReadKey($true)
            $msg = ''
            switch ($key.Key) {
                'UpArrow'   { $cur = ($cur - 1 + $n) % $n }
                'K'         { $cur = ($cur - 1 + $n) % $n }
                'DownArrow' { $cur = ($cur + 1) % $n }
                'J'         { $cur = ($cur + 1) % $n }
                'Spacebar'  { if (-not $Single) { $sel[$cur] = -not $sel[$cur] } }
                'A'         { if (-not $Single) { $all = -not ($sel -contains $false); for ($i = 0; $i -lt $n; $i++) { $sel[$i] = -not $all } } }
                'Q'         { [Console]::SetCursorPosition(0, $top); Write-Host 'Cancelled.'; throw 'cancelled' }
                'Escape'    { [Console]::SetCursorPosition(0, $top); Write-Host 'Cancelled.'; throw 'cancelled' }
                'Enter' {
                    if ($Single) { for ($i = 0; $i -lt $n; $i++) { $sel[$i] = ($i -eq $cur) }; break }
                    if (@($sel | Where-Object { $_ }).Count -ge $Min) { break }
                    $msg = "Select at least $Min (space to toggle)."
                }
            }
            if ($key.Key -eq 'Enter' -and -not $msg) { break }
        }
    } finally { [Console]::CursorVisible = $true }

    # Collapse the menu into one summary line.
    [Console]::SetCursorPosition(0, $top)
    for ($i = 0; $i -lt $height; $i++) { Write-Host (' ' * $cols) }
    [Console]::SetCursorPosition(0, $top)
    $picked = @(for ($i = 0; $i -lt $n; $i++) { if ($sel[$i]) { $labels[$i] } }) -join ', '
    if (-not $picked) { $picked = 'none' }
    Write-Host "  $CHECK " -ForegroundColor Green -NoNewline
    Write-Host "$title " -NoNewline
    Write-Host $picked -ForegroundColor Cyan
    return , $sel
}

function Select-ByName([string[]]$wanted, [string[]]$names, [string]$kind) {
    foreach ($x in $wanted) {
        if ($x -ne 'all' -and $x -ne 'none' -and $names -notcontains $x) { Stop-Install "unknown ${kind}: $x" }
    }
    [bool[]]@($names | ForEach-Object { ($wanted -contains 'all') -or ($wanted -contains $_) })
}

# --------------------------------------------------------------- questions --
# 1. skills
$sNames = [string[]]@($SkillList | ForEach-Object { $_.Name })
if ($Skills) {
    $SSel = Select-ByName (Split-List $Skills) $sNames 'skill'
} else {
    $SSel = [bool[]]@($sNames | ForEach-Object { $true })
    if ($Interactive) {
        $SSel = Show-Menu 'Which skills?' $sNames ([string[]]@($SkillList | ForEach-Object { $_.Desc })) $SSel -Min 1
    }
}

# 2. coding agents
$tIds = [string[]]@($Targets | ForEach-Object { $_.Id })
if ($To) {
    $TSel = Select-ByName (Split-List $To) $tIds 'agent'
} else {
    $TSel = [bool[]]@($Targets | ForEach-Object { Test-Detected $_ })
    if ($Interactive) {
        $descs = @($Targets | ForEach-Object {
            $d = Show-Tilde (Get-SkillsDir $_.Id 'global'); if (Test-Detected $_) { "detected - $d" } else { $d } })
        $TSel = Show-Menu 'Install for which coding agents?' ([string[]]@($Targets.Name)) $descs $TSel -Min 1
    } elseif (-not ($TSel -contains $true)) {
        Stop-Install 'no coding agent detected; pass -To claude,codex,copilot'
    }
}

# 3. scope
$Scope = 'global'
if ($Project) { $Scope = 'project' }
elseif (-not $Global -and $Interactive) {
    $r = Show-Menu 'Where should they go?' @('Global', 'This project') @('for you, in every project (~\...)', "only in $(Show-Tilde (Get-Location).Path)") @($true, $false) -Single
    if ($r[1]) { $Scope = 'project' }
}

# 4. custom agents (only for targets that support them)
$aNames = [string[]]@($AgentList | ForEach-Object { $_.Name })
$wantsAgents = $false
for ($i = 0; $i -lt $Targets.Count; $i++) { if ($TSel[$i] -and (Get-AgentsDir $Targets[$i].Id $Scope)) { $wantsAgents = $true } }
$ASel = [bool[]]@($aNames | ForEach-Object { $wantsAgents })
if ($aNames.Count -gt 0 -and $wantsAgents) {
    if ($Agents) {
        $ASel = Select-ByName (Split-List $Agents) $aNames 'custom agent'
    } elseif ($Interactive) {
        $ASel = Show-Menu 'Also install custom agents? (Claude Code, Copilot)' $aNames ([string[]]@($AgentList | ForEach-Object { $_.Desc })) $ASel
    }
}

# ----------------------------------------------------------------- confirm --
$nSkills = @($SSel | Where-Object { $_ }).Count
$nAgents = @($ASel | Where-Object { $_ }).Count
if ($Interactive) {
    Write-Host ''
    Write-Host '  ? ' -ForegroundColor Magenta -NoNewline
    Write-Host "Install $nSkills skill(s) and $nAgents agent(s)? [Y/n] " -NoNewline
    $answer = Read-Host
    if ($answer -match '^[nN]') { Write-Host '  Cancelled.' -ForegroundColor DarkGray; return }
}

# ----------------------------------------------------------------- install --
function Write-Ok([string]$text, [string]$extra = '') {
    Write-Host "  $CHECK " -ForegroundColor Green -NoNewline
    Write-Host $text -NoNewline
    Write-Host " $extra" -ForegroundColor DarkGray
}

Write-Host ''
for ($ti = 0; $ti -lt $Targets.Count; $ti++) {
    if (-not $TSel[$ti]) { continue }
    $t = $Targets[$ti]
    $sdir = Get-SkillsDir $t.Id $Scope
    Write-Host "  $($t.Name) " -ForegroundColor Cyan -NoNewline
    Write-Host "-> $(Show-Tilde $sdir)" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $sdir | Out-Null
    for ($si = 0; $si -lt $SkillList.Count; $si++) {
        if (-not $SSel[$si]) { continue }
        $name = $SkillList[$si].Name
        $dest = Join-Path $sdir $name
        $note = ''
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest; $note = '(updated)' }
        Copy-Item -Recurse -Path (Join-Path $Src "skills\$name") -Destination $dest
        Get-ChildItem $dest -Recurse -Directory -Filter __pycache__ | Remove-Item -Recurse -Force
        Write-Ok $name $note
    }
    $adir = Get-AgentsDir $t.Id $Scope
    if ($adir -and $nAgents -gt 0) {
        New-Item -ItemType Directory -Force -Path $adir | Out-Null
        for ($ai = 0; $ai -lt $AgentList.Count; $ai++) {
            if (-not $ASel[$ai]) { continue }
            $a = $AgentList[$ai]
            if ($t.Id -eq 'copilot') {
                # Copilot wants NAME.agent.md; drop the Claude-specific tools line.
                $dest = Join-Path $adir "$($a.Name).agent.md"
                $fm = 0
                $out = foreach ($line in (Get-Content -LiteralPath $a.Path -Encoding UTF8)) {
                    if ($line.Trim() -eq '---') { $fm++ }
                    if (-not ($fm -eq 1 -and $line -match '^tools\s*:')) { $line }
                }
                [IO.File]::WriteAllText($dest, (($out -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
            } else {
                $dest = Join-Path $adir "$($a.Name).md"
                Copy-Item -Path $a.Path -Destination $dest -Force
            }
            Write-Ok $a.Name "agent -> $(Show-Tilde $dest)"
        }
    }
    Write-Host ''
}

Write-Host "  $STAR Done. " -ForegroundColor Magenta -NoNewline
Write-Host 'Restart your coding agent so it loads the new skills.'
Write-Host ''

} catch {
    if ($_.Exception.Message -ne 'cancelled') { Write-Host "  x $($_.Exception.Message)" -ForegroundColor Red }
} finally {
    if ($Tmp -and (Test-Path $Tmp)) { Remove-Item -Recurse -Force $Tmp }
}
