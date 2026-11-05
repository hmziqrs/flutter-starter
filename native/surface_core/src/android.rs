//! JNI exports for `com.example.surfacecore.SurfaceCore`.
//!
//! Strings cross as UTF-8 `byte[]`, not `jstring`. JNI's string functions use Modified UTF-8,
//! so an emoji in a display name would be rejected or corrupted by `NewStringUTF`.
//!
//! The package is deliberately not `com.example.starter`: JNI symbol names contain it, and
//! `tool/rename_app.py` rewrites that one, which would break the lookup after a rename.

#![allow(non_snake_case)]

use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr;

use jni_sys::{JNIEnv, jbyte, jbyteArray, jclass, jdouble, jsize};

use crate::{Limits, format_percent, guarded_json, probe, snapshot_json};

/// Copies a Java `byte[]`. Null stays `None`.
///
/// # Safety
/// `env` is the valid JNI environment of the current thread.
unsafe fn read_bytes(env: *mut JNIEnv, array: jbyteArray) -> Option<Vec<u8>> {
    if array.is_null() {
        return None;
    }
    // SAFETY: `env` is valid and `array` is a live local reference from the caller.
    unsafe {
        let functions = &**env;
        let length = (functions.v1_1.GetArrayLength)(env, array);
        let mut bytes = vec![0_u8; usize::try_from(length).unwrap_or_default()];
        (functions.v1_1.GetByteArrayRegion)(
            env,
            array,
            0,
            length,
            bytes.as_mut_ptr().cast::<jbyte>(),
        );
        Some(bytes)
    }
}

/// Copies `text` into a new Java `byte[]`. Null means Java already has a pending exception.
///
/// # Safety
/// `env` is the valid JNI environment of the current thread.
unsafe fn write_bytes(env: *mut JNIEnv, text: &str) -> jbyteArray {
    let Ok(length) = jsize::try_from(text.len()) else {
        return ptr::null_mut();
    };
    // SAFETY: `env` is valid, and the array is checked before it is written.
    unsafe {
        let functions = &**env;
        let array = (functions.v1_1.NewByteArray)(env, length);
        if !array.is_null() {
            (functions.v1_1.SetByteArrayRegion)(
                env,
                array,
                0,
                length,
                text.as_ptr().cast::<jbyte>(),
            );
        }
        array
    }
}

fn utf8(bytes: Option<&[u8]>) -> Result<Option<&str>, ()> {
    bytes.map_or(Ok(None), |b| {
        std::str::from_utf8(b).map(Some).map_err(|_| ())
    })
}

/// # Safety
/// Called by the JVM with a valid environment.
#[unsafe(no_mangle)]
pub unsafe extern "system" fn Java_com_example_surfacecore_SurfaceCore_nativeVersion(
    env: *mut JNIEnv,
    _class: jclass,
) -> jbyteArray {
    // SAFETY: `env` comes straight from the JVM.
    unsafe { write_bytes(env, env!("CARGO_PKG_VERSION")) }
}

/// # Safety
/// Called by the JVM with a valid environment and local references.
#[unsafe(no_mangle)]
pub unsafe extern "system" fn Java_com_example_surfacecore_SurfaceCore_nativeFetchSnapshot(
    env: *mut JNIEnv,
    _class: jclass,
    base_url: jbyteArray,
    token: jbyteArray,
) -> jbyteArray {
    let json = guarded_json(AssertUnwindSafe(|| {
        // SAFETY: `env` and both references come straight from the JVM.
        let (base_url, token) = unsafe { (read_bytes(env, base_url), read_bytes(env, token)) };
        match (utf8(base_url.as_deref()), utf8(token.as_deref())) {
            (Ok(base_url), Ok(token)) => snapshot_json(base_url, token),
            _ => snapshot_json(None, None),
        }
    }));
    // SAFETY: `env` comes straight from the JVM.
    unsafe { write_bytes(env, &json) }
}

/// # Safety
/// Called by the JVM with a valid environment and local references.
#[unsafe(no_mangle)]
pub unsafe extern "system" fn Java_com_example_surfacecore_SurfaceCore_nativeProbeUrl(
    env: *mut JNIEnv,
    _class: jclass,
    url: jbyteArray,
) -> jbyteArray {
    let json = guarded_json(AssertUnwindSafe(|| {
        // SAFETY: `env` and the reference come straight from the JVM.
        let url = unsafe { read_bytes(env, url) };
        let url = utf8(url.as_deref()).ok().flatten().unwrap_or_default();
        probe(url, Limits::default())
    }));
    // SAFETY: `env` comes straight from the JVM.
    unsafe { write_bytes(env, &json) }
}

/// # Safety
/// Called by the JVM with a valid environment.
#[unsafe(no_mangle)]
pub unsafe extern "system" fn Java_com_example_surfacecore_SurfaceCore_nativeFormatPercent(
    env: *mut JNIEnv,
    _class: jclass,
    progress: jdouble,
) -> jbyteArray {
    let text = catch_unwind(|| format_percent(progress)).unwrap_or_else(|_| "--".to_owned());
    // SAFETY: `env` comes straight from the JVM.
    unsafe { write_bytes(env, &text) }
}
