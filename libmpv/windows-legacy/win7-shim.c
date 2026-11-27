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

static HRESULT WINAPI fj_PathCchRemoveFileSpec(PWSTR path, SIZE_T size)
{
    if (!path || size == 0) return E_INVALIDARG;
    return PathRemoveFileSpecW(path) ? S_OK : S_FALSE;
}

HRESULT (WINAPI *__imp_PathCchRemoveFileSpec)(PWSTR, SIZE_T) = fj_PathCchRemoveFileSpec;
