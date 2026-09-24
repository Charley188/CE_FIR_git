param(
    [Parameter(Mandatory=$true)][decimal]$FrequencyMHz,
    [decimal]$SampleRateMHz = 4800
)
$ErrorActionPreference = 'Stop'
if ($SampleRateMHz -le 0 -or $FrequencyMHz -lt (-$SampleRateMHz/2) -or $FrequencyMHz -ge ($SampleRateMHz/2)) {
    throw 'NCO frequency must be in [-Fs/2, Fs/2). This is the signed NCO offset, not the analog RF frequency.'
}
[decimal]$scale = 281474976710656
[long]$word = [decimal]::Round($FrequencyMHz / $SampleRateMHz * $scale, 0, [MidpointRounding]::AwayFromZero)
if ($word -ge 140737488355328) { throw 'Rounded frequency is outside the signed 48-bit range.' }
[long]$unsignedWord = $word
if ($unsignedWord -lt 0) { $unsignedWord += 281474976710656 }
[pscustomobject]@{
    NcoMHz = $FrequencyMHz
    SampleRateMHz = $SampleRateMHz
    VioHex = ('{0:X12}' -f $unsignedWord)
    ActualNcoMHz = ([decimal]$word * $SampleRateMHz / $scale)
}
