
# Listaroo

**Listaroo** is a simple shopping list app developed using SwiftUI. This project was created as a personal learning exercise to explore iOS development concepts such as state management, data persistence, and UI customization. The project also marks a collaboration with the AI tool, ChatGPT, which assisted in implementing several features and resolving issues during development.
## Features

- Create shopping lists: Add, edit, and delete shopping lists.

- Add items: Within each list, you can add items with different price types (per unit or by weight).

- Automatic total calculation: The total price of the items is automatically calculated for both selected items and all items.

- Edit items: Items can be edited at any time without losing the total price calculation.

- Data persistence: Lists are saved locally on the device using `UserDefaults`.
## Technologies Used

**SwiftUI:** Framework used to build the user interface declaratively.

**Combine:** Used for reactivity and state management between the ViewModel and Views.

**UserDefaults:** For local persistence of shopping lists.


## Screenshots

(Comming soon)

## Installation

Clone Listaroo 

1 - Clone this repository:

```bash
git clone https://github.com/otaviolourenco/shoppingList.git
```

2 - Open the project in Xcode:
```bash
cd shoppingList
open shoppingList.xcodeproj
```

3 - Run the project on a simulator or a real device.
## Project Structure

**ViewModel:** Manages data and business logic. Responsible for creating, editing, and deleting lists and items.

**Views:** Built using SwiftUI, the Views are responsible for the user interface and display the lists and their items.

**Models:** Define the structure of the ` Item` and `ShoppingList` objects used in the app.



## Contribution

This is a personal learning project, but any suggestions or contributions are welcome! Feel free to open issues or pull requests.


## License

This project is licensed under the [MIT](https://choosealicense.com/licenses/mit/) License. See the LICENSE file for details.




## 🔗 Links
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/otavio-lourenco/)
