import React from 'react';
import { View, StyleSheet, Image } from 'react-native';
import { ThemedText } from './ThemedText';
import { StageForm } from '../types';
import { getPetImageAsset } from '../assets/petImages';

interface PetDisplayProps {
  stage: StageForm;
  size?: number;
  showName?: boolean;
}

/**
 * Display the current pet form with image and name
 */
export function PetDisplay({ stage, size = 120, showName = true }: PetDisplayProps) {
  
  // Get pet image asset for this stage
  const petAsset = getPetImageAsset(stage.asset);
  
  // Fallback for missing assets
  const getBackgroundColor = () => {
    if (petAsset) {
      return petAsset.color;
    }
    // Fallback colors if asset not found
    const colors = [
      '#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336',
      '#00BCD4', '#8BC34A', '#FFC107', '#E91E63', '#607D8B',
      '#795548', '#FF5722', '#3F51B5', '#009688', '#CDDC39',
      '#673AB7', '#FF9800', '#9E9E9E', '#FF6F00', '#FFD700'
    ];
    return colors[stage.i % colors.length];
  };

  return (
    <View style={styles.container}>
      {/* Placeholder pet image */}
      <View 
        style={[
          styles.petImage,
          { 
            width: size, 
            height: size,
            backgroundColor: getBackgroundColor(),
          }
        ]}
      >
        {/* Show enhanced emoji from asset or fallback */}
        <ThemedText style={[styles.petEmoji, { fontSize: size * 0.4 }]}>
          {petAsset ? petAsset.emoji : getPetEmoji(stage.name)}
        </ThemedText>
        
        {/* Stage indicator for better visual distinction */}
        <View style={styles.stageIndicator}>
          <ThemedText style={[styles.stageNumber, { fontSize: size * 0.15 }]}>
            {stage.i + 1}
          </ThemedText>
        </View>
      </View>
      
      {showName && (
        <View style={styles.nameContainer}>
          <ThemedText style={styles.petName}>
            {stage.name}
          </ThemedText>
          {petAsset && (
            <ThemedText style={styles.petDescription}>
              {petAsset.description}
            </ThemedText>
          )}
        </View>
      )}
    </View>
  );
}

/**
 * Get emoji representation for each pet stage
 */
function getPetEmoji(stageName: string): string {
  const emojiMap: { [key: string]: string } = {
    'Tadpole': '🐸',
    'Minnow': '🐟',
    'Frog': '🐸',
    'Hermit Crab': '🦀',
    'Starfish': '⭐',
    'Jellyfish': '🪼',
    'Squid': '🦑',
    'Seahorse': '🐴',
    'Dolphin': '🐬',
    'Shark': '🦈',
    'Otter': '🦦',
    'Fox': '🦊',
    'Lynx': '🐱',
    'Wolf': '🐺',
    'Bear': '🐻',
    'Bison': '🦬',
    'Elephant': '🐘',
    'Rhino': '🦏',
    'Lion': '🦁',
    'Floating God': '✨'
  };
  
  return emojiMap[stageName] || '🐾';
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginVertical: 10,
  },
  petImage: {
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#E0E0E0',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
    position: 'relative',
  },
  petEmoji: {
    fontWeight: 'bold',
  },
  stageIndicator: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 10,
    minWidth: 20,
    paddingHorizontal: 6,
    paddingVertical: 2,
    alignItems: 'center',
  },
  stageNumber: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  nameContainer: {
    alignItems: 'center',
    marginTop: 8,
  },
  petName: {
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
  petDescription: {
    fontSize: 14,
    color: '#666666',
    textAlign: 'center',
    marginTop: 4,
    fontStyle: 'italic',
  },
});