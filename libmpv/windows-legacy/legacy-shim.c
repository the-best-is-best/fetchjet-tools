#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <objbase.h>
#include <shlwapi.h>
#include <string.h>

struct fj_mta {
    HANDLE ready;
    HANDLE done;
    HANDLE thread;
    HRESULT result;
};

static DWORD WINAPI fj_mta_thread(LPVOID param)
{
    struct fj_mta *mta = (struct fj_mta *)param;
    mta->result = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    SetEvent(mta->ready);
    if (SUCCEEDED(mta->result)) {
        WaitForSingleObject(mta->done, INFINITE);
        CoUninitialize();
    }
    return 0;
}

HRESULT WINAPI CoIncrementMTAUsage(CO_MTA_USAGE_COOKIE *cookie)
{
    if (!cookie) return E_INVALIDARG;
    *cookie = NULL;
    struct fj_mta *mta = (struct fj_mta *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof *mta);
    if (!mta) return E_OUTOFMEMORY;
    mta->ready = CreateEventW(NULL, TRUE, FALSE, NULL);
    mta->done = CreateEventW(NULL, TRUE, FALSE, NULL);
    mta->thread = mta->ready && mta->done ? CreateThread(NULL, 0, fj_mta_thread, mta, 0, NULL) : NULL;
    if (!mta->thread) {
        if (mta->ready) CloseHandle(mta->ready);
        if (mta->done) CloseHandle(mta->done);
        HeapFree(GetProcessHeap(), 0, mta);
        return E_OUTOFMEMORY;
    }
    WaitForSingleObject(mta->ready, INFINITE);
    HRESULT result = mta->result;
    if (FAILED(result)) {
        WaitForSingleObject(mta->thread, INFINITE);
        CloseHandle(mta->thread);
        CloseHandle(mta->ready);
        CloseHandle(mta->done);
        HeapFree(GetProcessHeap(), 0, mta);
        return result;
    }
    *cookie = (CO_MTA_USAGE_COOKIE)mta;
    return S_OK;
}

HRESULT WINAPI CoDecrementMTAUsage(CO_MTA_USAGE_COOKIE cookie)
{
    struct fj_mta *mta = (struct fj_mta *)cookie;
    if (!mta) return E_INVALIDARG;
    SetEvent(mta->done);
    WaitForSingleObject(mta->thread, INFINITE);
    CloseHandle(mta->thread);
    CloseHandle(mta->ready);
    CloseHandle(mta->done);
    HeapFree(GetProcessHeap(), 0, mta);
    return S_OK;
}

HRESULT (WINAPI *__imp_CoIncrementMTAUsage)(CO_MTA_USAGE_COOKIE *) = CoIncrementMTAUsage;
HRESULT (WINAPI *__imp_CoDecrementMTAUsage)(CO_MTA_USAGE_COOKIE) = CoDecrementMTAUsage;

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
