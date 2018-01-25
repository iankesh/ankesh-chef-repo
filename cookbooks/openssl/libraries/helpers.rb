module OpenSSLCookbook
  # Helper functions for the OpenSSL cookbook.
  module Helpers
    def self.included(_base)
      require 'openssl' unless defined?(OpenSSL)
    end

    # Path helpers
    def get_key_filename(cert_filename)
      cert_file_path, cert_filename = ::File.split(cert_filename)
      cert_filename = ::File.basename(cert_filename, ::File.extname(cert_filename))
      cert_file_path + ::File::SEPARATOR + cert_filename + '.key'
    end

    # Validation helpers
    def key_length_valid?(number)
      number >= 1024 && number & (number - 1) == 0
    end

    def dhparam_pem_valid?(dhparam_pem_path)
      # Check if the dhparam.pem file exists
      # Verify the dhparam.pem file contains a key
      return false unless ::File.exist?(dhparam_pem_path)
      dhparam = OpenSSL::PKey::DH.new File.read(dhparam_pem_path)
      dhparam.params_ok?
    end

    # given either a key file path or key file content see if it's actually
    # a private key
    def priv_key_file_valid?(key_file, key_password = nil)
      # if the file exists try to read the content
      # if not assume we were passed the key and set the string to the content
      key_content = ::File.exist?(key_file) ? File.read(key_file) : key_file

      begin
        key = OpenSSL::PKey::RSA.new key_content, key_password
      rescue OpenSSL::PKey::RSAError
        return false
      end
      key.private?
    end

    # return an array of all valid openssl ciphers on this host
    def valid_ciphers
      OpenSSL::Cipher.ciphers
    end

    # Generators
    def gen_dhparam(key_length, generator)
      raise ArgumentError, 'Key length must be a power of 2 greater than or equal to 1024' unless key_length_valid?(key_length)
      raise TypeError, 'Generator must be an integer' unless generator.is_a?(Integer)

      OpenSSL::PKey::DH.new(key_length, generator)
    end

    # Given the key length generate an RSA private key
    def gen_rsa_priv_key(key_length)
      raise ArgumentError, 'Key length must be a power of 2 greater than or equal to 1024' unless key_length_valid?(key_length)

      OpenSSL::PKey::RSA.new(key_length)
    end

    def gen_rsa_pub_key(priv_key, priv_key_password = nil)
      # if the file exists try to read the content
      # if not assume we were passed the key and set the string to the content
      key_content = ::File.exist?(priv_key) ? File.read(priv_key) : priv_key
      key = OpenSSL::PKey::RSA.new key_content, priv_key_password
      key.public_key.to_pem
    end

    # Key manipulation helpers
    # Returns a pem string
    def encrypt_rsa_key(rsa_key, key_password, key_cipher)
      raise TypeError, 'rsa_key must be a Ruby OpenSSL::PKey::RSA object' unless rsa_key.is_a?(OpenSSL::PKey::RSA)
      raise TypeError, 'key_password must be a string' unless key_password.is_a?(String)
      raise TypeError, 'key_cipher must be a string' unless key_cipher.is_a?(String)
      raise ArgumentError, 'Specified key_cipher is not available on this system' unless OpenSSL::Cipher.ciphers.include?(key_cipher)

      cipher = OpenSSL::Cipher.new(key_cipher)
      rsa_key.to_pem(cipher, key_password)
    end
  end
end
