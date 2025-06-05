let shuffledNames = [];
let currentIndex = 0;

exports.handler = async (event) => {
  console.log('Received event', event);
  // Parse environment variables with default values
  const names = JSON.parse(process.env.NAMES || '["Arthur","Martin","Douglas","Carolyn"]');
  const shuffle = process.env.SHUFFLE === 'true';

  if (!shuffle) {
    // If not shuffle, return a random name from the names array
    const randomName = names[Math.floor(Math.random() * names.length)];
    return {
      statusCode: 200,
      body: JSON.stringify(randomName),
    };
  } else {
    // If shuffle, shuffle names and persist in memory
    if (shuffledNames.length === 0 || currentIndex >= shuffledNames.length) {
      shuffledNames = shuffleArray([...names]); // Shuffle a copy of the names array
      currentIndex = 0; // Reset index
    }

    const nameToReturn = shuffledNames[currentIndex];
    currentIndex += 1; // Move to the next index

    return {
      statusCode: 200,
      body: JSON.stringify(nameToReturn),
    };
  }
};

// Helper function to shuffle an array
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]]; // Swap elements
  }
  return array;
}
