  class AES
    require 'openssl'
    require 'digest/sha2'
    require 'base64'


    @alg = "AES-256-CBC"


    @digest = Digest::SHA256.new
    @digest.update("decipher")
    @key = @digest.digest




    @aes = OpenSSL::Cipher::Cipher.new(@alg)
    @aes.encrypt
    @aes.key = @key

    def self.cipher (data)
      cipher = @aes.update(data)
      cipher << @aes.final
      [cipher].pack('m')
    end

    def self.decipher (data)
      decode_cipher = OpenSSL::Cipher::Cipher.new(@alg)
      decode_cipher.decrypt
      decode_cipher.key = @key
      plain = decode_cipher.update(data.unpack('m')[0])
      plain << decode_cipher.final
    end
  end
