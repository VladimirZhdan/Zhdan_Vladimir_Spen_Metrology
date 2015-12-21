	static private final int N = 10;
    static private final int M = 10;

    static public LinkedList<BufferedImage> splitPicture(BufferedImage image) {
        int startX = 0, startY = 0, endX = image.getWidth() - 1, endY = image.getHeight() - 1;
        LinkedList <BufferedImage> lettersList = new LinkedList<BufferedImage>();

        while (columnEmpty(image, startX, startY, endY)) startX++;
        while (columnEmpty(image, endX, startY, endY)) endX--;
        while (stringEmpty(image, startY, startX, endX)) startY++;
        while (stringEmpty(image, endY, startX, endX)) endY--;

        for (int i = startY; i <= endY; i++)
            if (!stringEmpty(image, i, startX, endX)) {
                int startStr = i, endStr = i;
                while (endStr + 1 <= endY && !stringEmpty(image, endStr + 1, startX, endX))
                    endStr++;
                List <BufferedImage> stringLetters = splitString(image, startX, endX, startStr, endStr);
                lettersList.addAll(stringLetters);
                i = endStr;
            }	

        return lettersList;
    }

    static private boolean columnEmpty(BufferedImage image, int x, int start, int end) {
        for (int i = start; i <= end; i++)
            if (image.getRGB(x, i) != Color.WHITE.getRGB())
                return false;
        return true;
    }

    static private boolean stringEmpty(BufferedImage image, int y, int start, int end) {
        for (int i = start; i <= end; i++)
            if (image.getRGB(i, y) != Color.WHITE.getRGB())
                return false;
        return true;
    }

    static private LinkedList <BufferedImage> splitString(BufferedImage image, int startX, int endX, int startY, int endY) {
        int i = startX;

        LinkedList <BufferedImage> letterList = new LinkedList<BufferedImage>();

        while (i <= endX) {
            int st = i;
            while (i + 1 <= endX && !columnEmpty(image, i + 1, startY, endY))
                i++;
            if (st < i) {
                letterList.add(getLetter(image, st, i, startY, endY));
            }
            i++;
        }

        return letterList;
    }

    static private BufferedImage getLetter(BufferedImage image, int sX, int eX, int sY, int eY) {
        while (columnEmpty(image, sX, sY, eY)) sX++;
        while (columnEmpty(image, eX, sY, eY)) eX--;
        while (stringEmpty(image, sY, sX, eX)) sY++;
        while (stringEmpty(image, eY, sX, eX)) eY--;

        BufferedImage letterImage = image.getSubimage(sX, sY, eX - sX + 1, eY - sY + 1);

        try {
            letterImage = Thumbnails.of(letterImage).size(N, M).asBufferedImage();
        } catch (Exception e) {
            e.printStackTrace();
        }

        toBinaryImage(letterImage);

        return letterImage;
    }

    static private void toBinaryImage(BufferedImage image) {
        final int MIN_BORDER = 200;
        for (int i = 0; i < image.getWidth(); i++)
            for (int j = 0; j < image.getHeight(); j++) {
                Color c = new Color(image.getRGB(i, j));
                if (c.getBlue() >= MIN_BORDER && c.getRed() >= MIN_BORDER && c.getGreen() >= MIN_BORDER) {
                    image.setRGB(i, j, Color.WHITE.getRGB());
                }
                else {
                    image.setRGB(i, j, Color.BLACK.getRGB());
                }
            }

    }

    static public byte[] getMapOfPicture(BufferedImage image) {
        final int COUNT_OF_INPUT_NEURONS = N * M;
        byte[] map = new byte[COUNT_OF_INPUT_NEURONS];
	
		
        for (int i = 0; i < N; i++)
            for (int j = 0; j < M; j++) {
                if (i < image.getWidth() && j < image.getHeight()) {
                    map[i * N + j] = (image.getRGB(i, j) == Color.BLACK.getRGB() ? (byte)1 : 0);
                }
            }

        return map;
    }
	
	public static final String INITIAL_DIR = new File("data").getAbsolutePath();
    @FXML
    private Canvas imageCanvas;
    @FXML
    private TextArea resultText;

    private BufferedImage textImage;
    private Fann neuralNetwork;

    @FXML
    private void loadImageAction() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setInitialDirectory(new File(INITIAL_DIR));
        File imageFile = fileChooser.showOpenDialog(null);

        if (imageFile != null) {
            try {
                textImage = ImageIO.read(imageFile);
                GraphicsContext gc = imageCanvas.getGraphicsContext2D();
                gc.drawImage(SwingFXUtils.toFXImage(textImage, null), 0, 0);
            } catch (IOException e) {
                showErrorDialog(e.getMessage());
            }
        }
    }

    @FXML
    private void loadNNFromFile() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setInitialDirectory(new File(INITIAL_DIR));
        File fileNN = fileChooser.showOpenDialog(null);
        if (fileNN != null)
            neuralNetwork = new Fann(fileNN.getAbsolutePath());
    }

    @FXML
    private void recognizePicture() {
        if (textImage == null) return;
        resultText.clear();
        LinkedList <BufferedImage> lettersList = ImageHandler.splitPicture(textImage);
        for (BufferedImage letterImage : lettersList) {
            byte[] letterMap = ImageHandler.getMapOfPicture(letterImage);
            char letter = recognizeLetter(letterMap);
            resultText.appendText(String.valueOf(letter));
        }
    }

    private char recognizeLetter(byte[] letterMap) {
        float[] inputData = new float[letterMap.length];
        for (int i = 0; i < letterMap.length; i++)
            inputData[i] = letterMap[i];
        float[] result = neuralNetwork.run(inputData);
        int indexOfMostLikely = 0;
        for (int i = 1; i < result.length; i++)
            if (result[indexOfMostLikely] < result[i])
                indexOfMostLikely = i;
        return (char)('a' + indexOfMostLikely);
    }

    @FXML
    private void showLearnWindow() {
        try {
            Parent root;
            root = FXMLLoader.load(getClass().getResource("ViewLW.fxml"));
            Stage stage = new Stage();
            stage.setTitle("NN Learner");
            stage.setScene(new Scene(root, 432, 129));
            stage.show();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    static public void showErrorDialog(String errorMessage) {
        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setTitle("Error");
        alert.setHeaderText("Произошла ошибка");
        alert.setContentText(errorMessage);
        alert.showAndWait();
    }
	
	@FXML
    BufferedImage image = null;
    @FXML
    TextField imageFilePath;
    @FXML
    TextField pictureText;

    @FXML
    private void choosePicture() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setInitialDirectory(new File(Controller.INITIAL_DIR));
        File imageFile = fileChooser.showOpenDialog(null);
        try {
            image = ImageIO.read(imageFile);
            imageFilePath.setText(imageFile.getPath());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @FXML
    private void learnAndSave() {
        LearnHelper.createLearningFile(image, pictureText.getText(), "data\\learn.txt");
        List<Layer> layerList = new ArrayList<Layer>();

        layerList.add(Layer.create(100, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));
        layerList.add(Layer.create(80, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));
        layerList.add(Layer.create(60, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));
        layerList.add(Layer.create(40, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));
        layerList.add(Layer.create(30, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));
        layerList.add(Layer.create(26, ActivationFunction.FANN_SIGMOID_SYMMETRIC, 0.01f));

        Fann fann = new Fann(layerList);
        Trainer trainer = new Trainer(fann);
        trainer.setTrainingAlgorithm(TrainingAlgorithm.FANN_TRAIN_RPROP);
        trainer.train(new File(Controller.INITIAL_DIR + "\\learn.txt").getAbsolutePath(), 100000, 100, 0.0001f);

        FileChooser fileChooser = new FileChooser();
        fileChooser.setInitialDirectory(new File(Controller.INITIAL_DIR));
        File nnFile = fileChooser.showSaveDialog(null);
        if (nnFile != null) {
            fann.save(nnFile.getAbsolutePath());
            showInfoMessage("Обучение прошло успешно, нейронная сеть сохранена в файл");
        }
    }

    public static void showInfoMessage(String text) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle("Info");
        alert.setHeaderText("Уведомление");
        alert.setContentText(text);
        alert.showAndWait();
    }