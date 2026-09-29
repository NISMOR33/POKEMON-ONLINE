module Graphics
  class << self
    alias fastforward_update update unless method_defined?(:fastforward_update)
    
    def update
      # Si on maintient ALT, on passe le jeu en x10 (400 fps au lieu de 40)
      if defined?(Input) && Input.press?(Input::ALT)
        self.frame_rate = 400
      else
        self.frame_rate = 40
      end
      fastforward_update
    end
  end
end
