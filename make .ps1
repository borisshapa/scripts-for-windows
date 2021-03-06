$working_dir = Get-Location
$makefile = Get-Content "$($working_dir)\Makefile.txt" | Out-String
$nl = [Environment]::NewLine
$blocks = ($makefile -split "$nl$nl" | Where-Object {$_})

$graph = @{}
$commands = @{}
$used = @{}

foreach($block in $blocks) {
    $depend, $cmds = $($block.Trim().Split($nl, 2))
    $vert, $children = $($depend.Split(": ", 2))
    
    $children = ($children -split " " |  Where-Object {$_})
    $graph[$vert] += $children
    
    $cmds = ($cmds -split $nl | Where-Object {$_})
    $commands[$vert] += $cmds
}

$topsort = [System.Collections.ArrayList]@()

Function Dfs($vert) {
    $used[$vert] = 1
    foreach($to in $graph[$vert]) {
        If ($to -and !$used[$to]) {
            Dfs($to)
        }
    }
    $topsort.Add($vert) > $null
}

$root = $args[0]
If (!$graph[$root]) {
    Write-Output "Such a goal does not exist."
    Exit
}

Dfs($root)

foreach($vert in $topsort) {
    foreach($cmd in $commands[$vert]) {
       Invoke-Expression $cmd
    }
}