/**
 * Pet image assets index
 * Maps stage names to their corresponding image assets
 * 
 * Note: This file provides the structure for pet images.
 * In a real native iOS implementation, these would be actual PNG/PDF files.
 * For this React Native prototype, we'll use color-coded placeholders.
 */

export interface PetImageAsset {
  name: string;
  emoji: string;
  color: string;
  backgroundColor: string;
  description: string;
}

/**
 * Pet image assets for all 20 stages
 * Each stage has a unique visual representation
 */
export const PET_IMAGE_ASSETS: { [key: string]: PetImageAsset } = {
  'pet_tadpole.png': {
    name: 'Tadpole',
    emoji: '🐸',
    color: '#4CAF50',
    backgroundColor: 'linear-gradient(135deg, #81C784, #4CAF50)',
    description: 'Small aquatic larva with a tail'
  },
  'pet_minnow.png': {
    name: 'Minnow', 
    emoji: '🐟',
    color: '#2196F3',
    backgroundColor: 'linear-gradient(135deg, #64B5F6, #2196F3)',
    description: 'Tiny silver fish'
  },
  'pet_frog.png': {
    name: 'Frog',
    emoji: '🐸', 
    color: '#4CAF50',
    backgroundColor: 'linear-gradient(135deg, #AED581, #4CAF50)',
    description: 'Green amphibian with strong legs'
  },
  'pet_hermit.png': {
    name: 'Hermit Crab',
    emoji: '🦀',
    color: '#FF7043',
    backgroundColor: 'linear-gradient(135deg, #FFAB91, #FF7043)', 
    description: 'Crab that lives in borrowed shells'
  },
  'pet_starfish.png': {
    name: 'Starfish',
    emoji: '⭐',
    color: '#FFB74D',
    backgroundColor: 'linear-gradient(135deg, #FFD54F, #FFB74D)',
    description: 'Five-armed marine creature'
  },
  'pet_jellyfish.png': {
    name: 'Jellyfish', 
    emoji: '🪼',
    color: '#E1BEE7',
    backgroundColor: 'linear-gradient(135deg, #F8BBD9, #E1BEE7)',
    description: 'Translucent floating marine animal'
  },
  'pet_squid.png': {
    name: 'Squid',
    emoji: '🦑',
    color: '#7986CB', 
    backgroundColor: 'linear-gradient(135deg, #9FA8DA, #7986CB)',
    description: 'Intelligent cephalopod with tentacles'
  },
  'pet_seahorse.png': {
    name: 'Seahorse',
    emoji: '🐴',
    color: '#26A69A',
    backgroundColor: 'linear-gradient(135deg, #4DB6AC, #26A69A)',
    description: 'Unique upright swimming fish'
  },
  'pet_dolphin.png': {
    name: 'Dolphin',
    emoji: '🐬',
    color: '#42A5F5',
    backgroundColor: 'linear-gradient(135deg, #64B5F6, #42A5F5)',
    description: 'Intelligent marine mammal'
  },
  'pet_shark.png': {
    name: 'Shark', 
    emoji: '🦈',
    color: '#546E7A',
    backgroundColor: 'linear-gradient(135deg, #78909C, #546E7A)',
    description: 'Apex predator of the seas'
  },
  'pet_otter.png': {
    name: 'Otter',
    emoji: '🦦',
    color: '#8D6E63',
    backgroundColor: 'linear-gradient(135deg, #A1887F, #8D6E63)',
    description: 'Playful semi-aquatic mammal'
  },
  'pet_fox.png': {
    name: 'Fox',
    emoji: '🦊', 
    color: '#FF8A65',
    backgroundColor: 'linear-gradient(135deg, #FFAB91, #FF8A65)',
    description: 'Clever woodland creature'
  },
  'pet_lynx.png': {
    name: 'Lynx',
    emoji: '🐱',
    color: '#A1887F',
    backgroundColor: 'linear-gradient(135deg, #BCAAA4, #A1887F)',
    description: 'Wild cat with tufted ears'
  },
  'pet_wolf.png': {
    name: 'Wolf',
    emoji: '🐺',
    color: '#616161', 
    backgroundColor: 'linear-gradient(135deg, #757575, #616161)',
    description: 'Pack-hunting canine'
  },
  'pet_bear.png': {
    name: 'Bear',
    emoji: '🐻',
    color: '#8D6E63',
    backgroundColor: 'linear-gradient(135deg, #A1887F, #8D6E63)',
    description: 'Large powerful omnivore'
  },
  'pet_bison.png': {
    name: 'Bison',
    emoji: '🦬',
    color: '#6D4C41',
    backgroundColor: 'linear-gradient(135deg, #8D6E63, #6D4C41)',
    description: 'Massive plains buffalo'
  },
  'pet_elephant.png': {
    name: 'Elephant', 
    emoji: '🐘',
    color: '#90A4AE',
    backgroundColor: 'linear-gradient(135deg, #B0BEC5, #90A4AE)',
    description: 'Gentle giant with trunk and tusks'
  },
  'pet_rhino.png': {
    name: 'Rhino',
    emoji: '🦏',
    color: '#757575',
    backgroundColor: 'linear-gradient(135deg, #9E9E9E, #757575)',
    description: 'Armored herbivore with horn'
  },
  'pet_lion.png': {
    name: 'Lion',
    emoji: '🦁',
    color: '#FFB74D', 
    backgroundColor: 'linear-gradient(135deg, #FFCC02, #FFB74D)',
    description: 'King of the savanna'
  },
  'pet_god.png': {
    name: 'Floating God',
    emoji: '✨',
    color: '#E1BEE7',
    backgroundColor: 'linear-gradient(135deg, #FFD700, #E1BEE7, #00BCD4)',
    description: 'Transcendent divine being - final evolution'
  }
};

/**
 * Get pet image asset by filename
 */
export function getPetImageAsset(assetFilename: string): PetImageAsset | null {
  return PET_IMAGE_ASSETS[assetFilename] || null;
}

/**
 * Get pet image asset by stage name
 */
export function getPetImageAssetByName(stageName: string): PetImageAsset | null {
  const asset = Object.values(PET_IMAGE_ASSETS).find(asset => asset.name === stageName);
  return asset || null;
}