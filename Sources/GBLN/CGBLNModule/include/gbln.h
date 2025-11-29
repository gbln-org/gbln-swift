#ifndef GBLN_H
#define GBLN_H

#pragma once

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * C-compatible error codes
 *
 * These match the Rust ErrorKind variants from gbln-rust
 */
typedef enum GblnErrorCode {
    Ok = 0,
    ErrorUnexpectedChar = 1,
    ErrorUnterminatedString = 2,
    ErrorUnexpectedToken = 3,
    ErrorUnexpectedEof = 4,
    ErrorInvalidSyntax = 5,
    ErrorIntOutOfRange = 6,
    ErrorStringTooLong = 7,
    ErrorTypeMismatch = 8,
    ErrorInvalidTypeHint = 9,
    ErrorDuplicateKey = 10,
    ErrorNullPointer = 11,
    ErrorIo = 12,
} GblnErrorCode;

/**
 * Value type enum for C FFI
 *
 * Represents the type of a GBLN value.
 * This allows C code to query the type without trying every accessor.
 */
typedef enum GblnValueType {
    I8 = 0,
    I16 = 1,
    I32 = 2,
    I64 = 3,
    U8 = 4,
    U16 = 5,
    U32 = 6,
    U64 = 7,
    F32 = 8,
    F64 = 9,
    Str = 10,
    Bool = 11,
    Null = 12,
    Object = 13,
    Array = 14,
} GblnValueType;

/**
 * Opaque pointer to a GBLN value
 *
 * This is a C-compatible wrapper around Rust's Value type.
 * C code sees this as an opaque pointer and must use the provided
 * accessor functions to interact with it.
 *
 * Note: This struct is intentionally opaque to C. The internal
 * Value type is not exposed in the C header.
 */
typedef struct GblnValue GblnValue;

/**
 * Opaque wrapper for GblnConfig
 */
typedef struct GblnConfig GblnConfig;

/**
 * Parse GBLN string into a value
 *
 * # Safety
 * - `input` must be a valid null-terminated UTF-8 string
 * - `out_value` must be a valid pointer to store the result
 * - Caller must free the returned value with `gbln_value_free()`
 *
 * # Returns
 * - `GBLN_OK` on success, with `out_value` set to the parsed value
 * - Error code on failure, with error details available via `gbln_last_error_message()`
 */
enum GblnErrorCode gbln_parse(const char *input, struct GblnValue **out_value);

/**
 * Free a GBLN value
 *
 * # Safety
 * - `value` must be a valid pointer returned from `gbln_parse()` or NULL
 * - Must not be called twice on the same pointer
 */
void gbln_value_free(struct GblnValue *value);

/**
 * Serialize GBLN value to compact string
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - Caller must free the returned string with `gbln_string_free()`
 *
 * # Returns
 * - Pointer to null-terminated C string on success
 * - NULL on error
 */
char *gbln_to_string(const struct GblnValue *value);

/**
 * Serialize GBLN value to formatted string
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - Caller must free the returned string with `gbln_string_free()`
 *
 * # Returns
 * - Pointer to null-terminated C string on success
 * - NULL on error
 */
char *gbln_to_string_pretty(const struct GblnValue *value);

/**
 * Free a string returned by GBLN functions
 *
 * # Safety
 * - `s` must be a valid pointer returned from GBLN functions or NULL
 * - Must not be called twice on the same pointer
 */
void gbln_string_free(char *s);

/**
 * Get last error message
 *
 * Returns NULL if no error occurred.
 * The returned pointer is valid until the next error occurs.
 * Caller must free with `gbln_string_free()`.
 */
char *gbln_last_error_message(void);

/**
 * Get last error suggestion
 *
 * Returns NULL if no suggestion is available.
 * The returned pointer is valid until the next error occurs.
 * Caller must free with `gbln_string_free()`.
 */
char *gbln_last_error_suggestion(void);

/**
 * Get field from object
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - `key` must be a valid null-terminated UTF-8 string
 * - Returns NULL if value is not an object or key not found
 * - Returned pointer is valid as long as the parent value is valid
 */
const struct GblnValue *gbln_object_get(const struct GblnValue *value, const char *key);

/**
 * Get array length
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - Returns 0 if value is not an array
 */
uintptr_t gbln_array_len(const struct GblnValue *value);

/**
 * Get array element by index
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - Returns NULL if value is not an array or index out of bounds
 * - Returned pointer is valid as long as the parent value is valid
 */
const struct GblnValue *gbln_array_get(const struct GblnValue *value, uintptr_t index);

/**
 * Get i8 value
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - `ok` will be set to true if value is i8, false otherwise
 */
int8_t gbln_value_as_i8(const struct GblnValue *value, bool *ok);

/**
 * Get i16 value
 */
int16_t gbln_value_as_i16(const struct GblnValue *value, bool *ok);

/**
 * Get i32 value
 */
int32_t gbln_value_as_i32(const struct GblnValue *value, bool *ok);

/**
 * Get i64 value
 */
int64_t gbln_value_as_i64(const struct GblnValue *value, bool *ok);

/**
 * Get u8 value
 */
uint8_t gbln_value_as_u8(const struct GblnValue *value, bool *ok);

/**
 * Get u16 value
 */
uint16_t gbln_value_as_u16(const struct GblnValue *value, bool *ok);

/**
 * Get u32 value
 */
uint32_t gbln_value_as_u32(const struct GblnValue *value, bool *ok);

/**
 * Get u64 value
 */
uint64_t gbln_value_as_u64(const struct GblnValue *value, bool *ok);

/**
 * Get f32 value
 */
float gbln_value_as_f32(const struct GblnValue *value, bool *ok);

/**
 * Get f64 value
 */
double gbln_value_as_f64(const struct GblnValue *value, bool *ok);

/**
 * Get string value
 *
 * # Safety
 * - Returns a pointer to a null-terminated C string
 * - Caller must free the returned string with `gbln_string_free()`
 * - Returns NULL if value is not a string
 */
char *gbln_value_as_string(const struct GblnValue *value, bool *ok);

/**
 * Get bool value
 */
bool gbln_value_as_bool(const struct GblnValue *value, bool *ok);

/**
 * Check if value is null
 */
bool gbln_value_is_null(const struct GblnValue *value);

/**
 * Create default I/O configuration
 *
 * Returns configuration for production I/O format:
 * - mini_mode: true
 * - compress: true
 * - compression_level: 6
 * - indent: 2
 * - strip_comments: true
 *
 * # Safety
 * Caller must free with `gbln_config_free()`
 */
struct GblnConfig *gbln_config_new_io(void);

/**
 * Create default source configuration
 *
 * Returns configuration for human-readable source:
 * - mini_mode: false
 * - compress: false
 * - compression_level: 6
 * - indent: 2
 * - strip_comments: false
 *
 * # Safety
 * Caller must free with `gbln_config_free()`
 */
struct GblnConfig *gbln_config_new_source(void);

/**
 * Create custom configuration
 *
 * # Parameters
 * - mini_mode: Use MINI GBLN (no whitespace)
 * - compress: Enable XZ compression
 * - compression_level: XZ level (0-9, where 9 is maximum)
 * - indent: Indentation width (0 = no indent)
 * - strip_comments: Remove comments in output
 *
 * # Safety
 * Caller must free with `gbln_config_free()`
 */
struct GblnConfig *gbln_config_new(bool mini_mode,
                                   bool compress,
                                   uint8_t compression_level,
                                   uintptr_t indent,
                                   bool strip_comments);

/**
 * Free configuration
 *
 * # Safety
 * - config must be a valid pointer from gbln_config_new_*() or NULL
 * - Must not be called twice on the same pointer
 */
void gbln_config_free(struct GblnConfig *config);

/**
 * Get mini_mode setting
 */
bool gbln_config_get_mini_mode(const struct GblnConfig *config);

/**
 * Get compress setting
 */
bool gbln_config_get_compress(const struct GblnConfig *config);

/**
 * Get compression_level setting
 */
uint8_t gbln_config_get_compression_level(const struct GblnConfig *config);

/**
 * Get indent setting
 */
uintptr_t gbln_config_get_indent(const struct GblnConfig *config);

/**
 * Get strip_comments setting
 */
bool gbln_config_get_strip_comments(const struct GblnConfig *config);

/**
 * Set mini_mode setting
 */
void gbln_config_set_mini_mode(struct GblnConfig *config, bool value);

/**
 * Set compress setting
 */
void gbln_config_set_compress(struct GblnConfig *config, bool value);

/**
 * Set compression_level setting (0-9)
 */
void gbln_config_set_compression_level(struct GblnConfig *config, uint8_t value);

/**
 * Set indent setting
 */
void gbln_config_set_indent(struct GblnConfig *config, uintptr_t value);

/**
 * Set strip_comments setting
 */
void gbln_config_set_strip_comments(struct GblnConfig *config, bool value);

/**
 * Get value type
 *
 * Returns the type of a GBLN value.
 * Eliminates need to try every as_* function.
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 */
enum GblnValueType gbln_value_type(const struct GblnValue *value);

/**
 * Get number of fields in object
 *
 * Returns 0 if value is not an object.
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 */
uintptr_t gbln_object_len(const struct GblnValue *value);

/**
 * Get object keys
 *
 * Returns array of null-terminated C strings.
 * Caller must free with `gbln_keys_free()`.
 *
 * Returns NULL if value is not an object.
 *
 * # Safety
 * - `value` must be a valid GblnValue pointer
 * - `out_count` must be a valid pointer to store the count
 * - Caller must free returned array with `gbln_keys_free()`
 */
char **gbln_object_keys(const struct GblnValue *value, uintptr_t *out_count);

/**
 * Free keys array
 *
 * Frees array returned by `gbln_object_keys()`.
 *
 * # Safety
 * - `keys` must be a valid pointer returned from `gbln_object_keys()`
 * - `count` must be the count returned from `gbln_object_keys()`
 * - Must not be called twice on the same pointer
 */
void gbln_keys_free(char **keys, uintptr_t count);

/**
 * Create i8 value
 */
struct GblnValue *gbln_value_new_i8(int8_t value);

/**
 * Create i16 value
 */
struct GblnValue *gbln_value_new_i16(int16_t value);

/**
 * Create i32 value
 */
struct GblnValue *gbln_value_new_i32(int32_t value);

/**
 * Create i64 value
 */
struct GblnValue *gbln_value_new_i64(int64_t value);

/**
 * Create u8 value
 */
struct GblnValue *gbln_value_new_u8(uint8_t value);

/**
 * Create u16 value
 */
struct GblnValue *gbln_value_new_u16(uint16_t value);

/**
 * Create u32 value
 */
struct GblnValue *gbln_value_new_u32(uint32_t value);

/**
 * Create u64 value
 */
struct GblnValue *gbln_value_new_u64(uint64_t value);

/**
 * Create f32 value
 */
struct GblnValue *gbln_value_new_f32(float value);

/**
 * Create f64 value
 */
struct GblnValue *gbln_value_new_f64(double value);

/**
 * Create string value
 *
 * # Args
 * - value: null-terminated UTF-8 string
 * - max_len: maximum string length (for type hint)
 *
 * # Returns
 * - GblnValue pointer on success
 * - NULL if string exceeds max_len or invalid UTF-8
 *
 * # Safety
 * - `value` must be a valid null-terminated UTF-8 string
 */
struct GblnValue *gbln_value_new_str(const char *value, uintptr_t max_len);

/**
 * Create boolean value
 */
struct GblnValue *gbln_value_new_bool(bool value);

/**
 * Create null value
 */
struct GblnValue *gbln_value_new_null(void);

/**
 * Create empty object
 */
struct GblnValue *gbln_value_new_object(void);

/**
 * Insert field into object
 *
 * # Safety
 * - `object` must be a GblnValue of type Object
 * - `key` must be a valid null-terminated UTF-8 string
 * - `value` ownership is transferred to the object
 *
 * # Returns
 * - GBLN_OK on success
 * - GBLN_ERROR_DUPLICATE_KEY if key already exists
 * - GBLN_ERROR_TYPE_MISMATCH if object is not an Object type
 * - GBLN_ERROR_NULL_POINTER if any pointer is null
 */
enum GblnErrorCode gbln_object_insert(struct GblnValue *object,
                                      const char *key,
                                      struct GblnValue *value);

/**
 * Create empty array
 */
struct GblnValue *gbln_value_new_array(void);

/**
 * Push value to array
 *
 * # Safety
 * - `array` must be a GblnValue of type Array
 * - `value` ownership is transferred to the array
 *
 * # Returns
 * - GBLN_OK on success
 * - GBLN_ERROR_TYPE_MISMATCH if array is not an Array type
 * - GBLN_ERROR_NULL_POINTER if any pointer is null
 */
enum GblnErrorCode gbln_array_push(struct GblnValue *array, struct GblnValue *value);

/**
 * Write GBLN value to I/O format file
 *
 * This function serialises the value according to the configuration and writes
 * it to the specified file. The file extension and compression are determined
 * by the config settings.
 *
 * # File Extensions
 * - `.io.gbln.xz`: MINI GBLN + XZ compression (compress=true)
 * - `.io.gbln`: MINI GBLN without compression (compress=false, mini_mode=true)
 * - `.gbln`: Pretty-printed source format (mini_mode=false)
 *
 * # Parameters
 * - value: GBLN value to write
 * - path: File path (null-terminated string)
 * - config: I/O configuration (if NULL, uses default io_format())
 *
 * # Returns
 * - GBLN_OK on success
 * - GBLN_ERROR_IO on file write failure
 * - GBLN_ERROR_NULL_POINTER if value or path is NULL
 * - Error details via gbln_last_error_message()
 *
 * # Safety
 * - value must be a valid GblnValue pointer
 * - path must be a valid null-terminated UTF-8 string
 * - config may be NULL (uses default)
 */
enum GblnErrorCode gbln_write_io(const struct GblnValue *value,
                                 const char *path,
                                 const struct GblnConfig *config);

/**
 * Read GBLN file from I/O format
 *
 * This function reads a file and automatically detects if it's XZ compressed.
 * The content is then parsed into a GBLN value.
 *
 * # Auto-Detection
 * The function checks for XZ magic bytes (FD 37 7A 58 5A 00) and automatically
 * decompresses if detected.
 *
 * # Parameters
 * - path: File path (null-terminated string)
 * - out_value: Pointer to store the parsed value
 *
 * # Returns
 * - GBLN_OK on success, with out_value set to parsed value
 * - GBLN_ERROR_IO on file read failure
 * - GBLN_ERROR_NULL_POINTER if path or out_value is NULL
 * - Parse errors on invalid GBLN content
 * - Error details via gbln_last_error_message()
 *
 * # Safety
 * - path must be a valid null-terminated UTF-8 string
 * - out_value must be a valid pointer to store the result
 * - Caller must free returned value with gbln_value_free()
 */
enum GblnErrorCode gbln_read_io(const char *path, struct GblnValue **out_value);

#endif  /* GBLN_H */
