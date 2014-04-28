module Bank
  class Config
    def default_packers
      [
        Serialize::PackTimeStamps,
        Serialize::PackIntegers,
        Serialize::PackBooleans
      ]
    end

    def default_unpackers
      [
        Serialize::UnpackTime,
        Serialize::UnpackDate,
        Serialize::UnpackBoolean
      ]
    end
  end
end
