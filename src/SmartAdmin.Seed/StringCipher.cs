
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace SmartAdmin.Seed
{
    public static class StringCipher
    {

        /// <summary>
        /// Generates a new random key.
        /// </summary>
        /// <param name="keyByteSize">Key size in bytes.</param>
        /// <param name="useHex">Use Hexadecimal format.</param>
        /// <returns>
        /// A Base64 or Hexadecimal string representing a byte array of random values.
        /// </returns>
        /// <remarks>
        /// The AES Key can be 128 bits = 16 bytes, 192 bits = 24 bytes or 256 bits = 32 bytes.
        /// </remarks>
        public static string GetNewRandom(int keyByteSize = 16, bool useHex = false)
        {
            byte[] randomArray = new byte[keyByteSize];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomArray);
            }
            if (useHex)
                return BitConverter.ToString(randomArray).Replace("-", "");
            else
                return Convert.ToBase64String(randomArray);
        }

        /// <summary>
        /// Encrypts plain text using the key and initialization vector (iv).
        /// </summary>
        /// <param name="key">The key in Base64 or Hexadecimal string format.</param>
        /// <param name="iv">The initialization vector (iv) in Base64 or Hexadecimal string format.</param>
        /// <param name="plainText">The text to be encrypted.</param>
        /// <param name="keyByteSize">Key size in bytes.</param>
        /// <param name="useHex">Use Hexadecimal format for key and iv.</param>
        /// <returns>
        /// A string AES encrypted using the key and initialization vector (iv).
        /// </returns>
        /// <remarks>
        /// The AES Key can be 128 bits = 16 bytes, 192 bits = 24 bytes or 256 bits = 32 bytes.
        /// </remarks>
        public static string EncryptString(string key, string iv, string plainText, int keyByteSize = 16, bool useHex = false)
        {
            byte[] keyBytes = new byte[keyByteSize];
            byte[] ivBytes = new byte[16];
            byte[] cipherBytes;

            if (useHex)
            {
                int len = keyByteSize * 2;
                for (int i = 0; i < len; i += 2)
                {
                    keyBytes[i / 2] = Convert.ToByte(key.Substring(i, 2), 16);
                    if (i < 32)
                        ivBytes[i / 2] = Convert.ToByte(iv.Substring(i, 2), 16);
                }
            }
            else
            {
                keyBytes = Convert.FromBase64String(key);
                ivBytes = Convert.FromBase64String(iv);
            }

            using (Aes aes = Aes.Create())
            {
                aes.Key = keyBytes;
                aes.IV = ivBytes;
                ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
                using MemoryStream memoryStream = new MemoryStream();
                using CryptoStream cryptoStream = new CryptoStream(memoryStream, encryptor, CryptoStreamMode.Write);
                using (StreamWriter streamWriter = new StreamWriter(cryptoStream))
                {
                    streamWriter.Write(plainText);
                }
                cipherBytes = memoryStream.ToArray();
            }
            return Convert.ToBase64String(cipherBytes);
        }

        /// <summary>
        /// Decrypts cipher text using the key and initialization vector (iv).
        /// </summary>
        /// <param name="key">The key in Base64 or Hexadecimal string format.</param>
        /// <param name="iv">The initialization vector (iv) in Base64 or Hexadecimal string format.</param>
        /// <param name="cipherText">The encrypted text.</param>
        /// <param name="keyByteSize">Key size in bytes.</param>
        /// <param name="useHex">Use Hexadecimal format for key and iv.</param>
        /// <returns>
        /// A string AES decrypted using the key and initialization vector (iv).
        /// </returns>
        /// <remarks>
        /// The AES Key can be 128 bits = 16 bytes, 192 bits = 24 bytes or 256 bits = 32 bytes.
        /// </remarks>
        public static string DecryptString(string key, string iv, string cipherText, int keyByteSize = 16, bool useHex = false)
        {
            byte[] keyBytes = new byte[keyByteSize];
            byte[] ivBytes = new byte[16];
            byte[] cipherBytes = Convert.FromBase64String(cipherText);

            if (useHex)
            {
                int len = keyByteSize * 2;
                for (int i = 0; i < len; i += 2)
                {
                    keyBytes[i / 2] = Convert.ToByte(key.Substring(i, 2), 16);
                    if (i < 32)
                        ivBytes[i / 2] = Convert.ToByte(iv.Substring(i, 2), 16);
                }
            }
            else
            {
                keyBytes = Convert.FromBase64String(key);
                ivBytes = Convert.FromBase64String(iv);
            }

            using Aes aes = Aes.Create();
            aes.Key = keyBytes;
            aes.IV = ivBytes;
            ICryptoTransform decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
            using MemoryStream memoryStream = new MemoryStream(cipherBytes);
            using CryptoStream cryptoStream = new CryptoStream(memoryStream, decryptor, CryptoStreamMode.Read);
            using StreamReader streamReader = new StreamReader(cryptoStream);
            return streamReader.ReadToEnd();
        }



    }

    
}
