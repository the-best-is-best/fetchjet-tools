#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <string.h>

static SRWLOCK fj_lock = SRWLOCK_INIT;
static CONDITION_VARIABLE fj_cond = CONDITION_VARIABLE_INIT;

BOOL WINAPI WaitOnAddress(volatile VOID *address, PVOID compare, SIZE_T size, DWORD milliseconds)
{
    BOOL ok = TRUE;
    AcquireSRWLockExclusive(&fj_lock);
    if (memcmp((const void *)address, compare, size) == 0) {
        if (!SleepConditionVariableSRW(&fj_cond, &fj_lock, milliseconds, 0)) {
            ok = FALSE;
        }
    }
    ReleaseSRWLockExclusive(&fj_lock);
    if (!ok) SetLastError(ERROR_TIMEOUT);
    return ok;
}

VOID WINAPI WakeByAddressAll(PVOID address)
{
    (void)address;
    AcquireSRWLockExclusive(&fj_lock);
    ReleaseSRWLockExclusive(&fj_lock);
    WakeAllConditionVariable(&fj_cond);
}

VOID WINAPI WakeByAddressSingle(PVOID address)
{
    WakeByAddressAll(address);
}

HRESULT WINAPI PathCchRemoveFileSpec(PWSTR path, SIZE_T size)
{
    if (!path || size == 0) return E_INVALIDARG;
    return PathRemoveFileSpecW(path) ? S_OK : S_FALSE;
}

HRESULT (WINAPI *__imp_PathCchRemoveFileSpec)(PWSTR, SIZE_T) = PathCchRemoveFileSpec;
BOOL (WINAPI *__imp_WaitOnAddress)(volatile VOID *, PVOID, SIZE_T, DWORD) = WaitOnAddress;
VOID (WINAPI *__imp_WakeByAddressAll)(PVOID) = WakeByAddressAll;
VOID (WINAPI *__imp_WakeByAddressSingle)(PVOID) = WakeByAddressSingle;

HRESULT WINAPI PathAllocCanonicalize(PCWSTR path, ULONG flags, PWSTR *out)
{
    (void)path;
    (void)flags;
    if (out) *out = NULL;
    return E_NOTIMPL;
}

HRESULT (WINAPI *__imp_PathAllocCanonicalize)(PCWSTR, ULONG, PWSTR *) = PathAllocCanonicalize;

HRESULT WINAPI PathAllocCombine(PCWSTR first, PCWSTR more, ULONG flags, PWSTR *out)
{
    (void)flags;
    if (!out) return E_INVALIDARG;
    *out = NULL;
    if (!first && !more) return E_INVALIDARG;
    size_t a = first ? wcslen(first) : 0;
    size_t b = more ? wcslen(more) : 0;
    BOOL absolute = b > 0 && (more[0] == L'\\' || more[0] == L'/' || (b > 1 && more[1] == L':'));
    if (absolute || a == 0) a = 0;
    BOOL slash = a > 0 && b > 0 && first[a - 1] != L'\\' && first[a - 1] != L'/';
    PWSTR result = (PWSTR)LocalAlloc(LMEM_FIXED, (a + b + 2) * sizeof(WCHAR));
    if (!result) return E_OUTOFMEMORY;
    if (a) memcpy(result, first, a * sizeof(WCHAR));
    if (slash) result[a++] = L'\\';
    if (b) memcpy(result + a, more, b * sizeof(WCHAR));
    result[a + b] = 0;
    *out = result;
    return S_OK;
}

HRESULT (WINAPI *__imp_PathAllocCombine)(PCWSTR, PCWSTR, ULONG, PWSTR *) = PathAllocCombine;
